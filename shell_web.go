package main

import (
	"bufio"
	"fmt"
	"github.com/gorilla/websocket"
	"io"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"sync"
	"time"
)

const (
	LogFile      = "dl.log"
	MaxLogSize   = 5 * 1024 * 1024
	MaxLogFiles  = 5
	HistoryLines = 3000
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

type Session struct {
	conn    *websocket.Conn
	stdinCh chan string
	stopCh  chan struct{}
	wg      sync.WaitGroup
	writeMu sync.Mutex
}

// 写日志并轮转，添加完整时间戳
func writeLog(line string) {
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	lineWithTime := fmt.Sprintf("[%s] %s", timestamp, line)

	fmt.Println(lineWithTime)

	f, err := os.OpenFile(LogFile, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err == nil {
		f.WriteString(lineWithTime + "\n")
		f.Close()
	}

	info, err := os.Stat(LogFile)
	if err == nil && info.Size() > MaxLogSize {
		rotateLogs()
	}
}

// 日志轮转，保留最多 MaxLogFiles 个
func rotateLogs() {
	oldest := fmt.Sprintf("%s.%d", LogFile, MaxLogFiles)
	if _, err := os.Stat(oldest); err == nil {
		os.Remove(oldest)
	}

	for i := MaxLogFiles - 1; i >= 1; i-- {
		src := fmt.Sprintf("%s.%d", LogFile, i)
		dst := fmt.Sprintf("%s.%d", LogFile, i+1)
		if _, err := os.Stat(src); err == nil {
			os.Rename(src, dst)
		}
	}

	os.Rename(LogFile, LogFile+".1")
	os.Create(LogFile)
	fmt.Println("Log rotated")
}

func tailLines(path string, n int) []string {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil
	}
	lines := strings.Split(string(data), "\n")
	if len(lines) > n {
		return lines[len(lines)-n:]
	}
	return lines
}

// 安全写 WS
func writeWS(session *Session, msg string) {
	session.writeMu.Lock()
	defer session.writeMu.Unlock()
	session.conn.WriteMessage(websocket.TextMessage, []byte(msg))
}

func wsHandler(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		fmt.Println("WS Upgrade error:", err)
		return
	}
	defer conn.Close()
	fmt.Println("WS connected:", r.RemoteAddr)

	session := &Session{
		conn:    conn,
		stdinCh: make(chan string, 10),
		stopCh:  make(chan struct{}),
	}

	// 发送最近日志
	for _, line := range tailLines(LogFile, HistoryLines) {
		writeWS(session, line)
	}

	// 接收消息
	go func() {
		for {
			_, data, err := conn.ReadMessage()
			if err != nil {
				close(session.stopCh)
				break
			}
			cmd := strings.TrimSpace(string(data))
			if cmd == "" {
				continue
			}
			// 不再判断前缀，所有输入都调用 execInteractive
			go execInteractive(session, cmd)
		}
	}()

	<-session.stopCh
	fmt.Println("WS disconnected:", r.RemoteAddr)
}

// 使用 bash -c 执行命令，支持管道、变量、重定向
func execInteractive(session *Session, args string) {
	if args == "" {
		return
	}

	cmd := exec.Command("bash", "-c", args)

	stdout, _ := cmd.StdoutPipe()
	stderr, _ := cmd.StderrPipe()
	stdin, _ := cmd.StdinPipe()

	if err := cmd.Start(); err != nil {
		writeLog(fmt.Sprintf("Failed to start command: %v", err))
		return
	}

	// stdout
	session.wg.Add(1)
	go func() {
		defer session.wg.Done()
		readPipeInteractive(stdout, session, "[stdout]")
	}()

	// stderr
	session.wg.Add(1)
	go func() {
		defer session.wg.Done()
		readPipeInteractive(stderr, session, "[stderr]")
	}()

	// stdin
	session.wg.Add(1)
	go func() {
		defer session.wg.Done()
		for {
			select {
			case line := <-session.stdinCh:
				stdin.Write([]byte(line + "\n"))
			case <-session.stopCh:
				return
			}
		}
	}()

	cmd.Wait()
	writeLog("--- process ended ---")
	session.wg.Wait()
}

func readPipeInteractive(pipe io.ReadCloser, session *Session, prefix string) {
	r := bufio.NewReader(pipe)
	for {
		line, err := r.ReadString('\n')
		if len(line) > 0 {
			line = strings.TrimRight(line, "\r\n")

			timestamp := time.Now().Format("15:04:05")
			lineWithTime := fmt.Sprintf("[%s] %s %s", timestamp, prefix, line)

			writeLog(fmt.Sprintf("%s %s", prefix, line))
			writeWS(session, lineWithTime)
		}
		if err != nil {
			return
		}
	}
}

func page(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html; charset=UTF-8")
	fmt.Fprint(w, `
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
body { font-family: monospace, "Courier New", sans-serif; background:#111; color:#0f0; margin:0; padding:0; display:flex; flex-direction:column; height:100vh;}
#log { white-space: pre-wrap; flex:1; overflow-y:auto; padding:10px; background:#111; scrollbar-width: thin; scrollbar-color: #0f0 #222;}
#log::-webkit-scrollbar { width: 8px; }
#log::-webkit-scrollbar-track { background: #222; }
#log::-webkit-scrollbar-thumb { background-color: #0f0; border-radius: 4px; }
#inputBar { display:flex; flex-direction:column; padding:5px; background:#222; }
#cmd { flex:1; padding:5px; font-size:16px; font-family: monospace, "Courier New", sans-serif; color:#0f0; background:#111; border:1px solid #0f0; width:100%; resize:none; height:80px; border-radius:5px; }
button { padding:5px 10px; font-size:16px; margin-top:5px; color:#0f0; background:#222; border:1px solid #0f0; cursor:pointer; width:100%; border-radius:5px; }
button:active { background:#0a0; }
</style>
</head>
<body>

<div id="log"></div>
<div id="inputBar">
<textarea id="cmd" placeholder="输入命令或交互输入，多行输入每行自动回车"></textarea>
<button onclick="sendCmd()">Send</button>
</div>

<script>
let ws = new WebSocket("ws://" + location.host + "/ws");
ws.onopen = () => console.log("WS connected");
ws.onerror = e => console.log("WS error", e);
ws.onclose = () => console.log("WS closed");

ws.onmessage = e => {
    let log = document.getElementById("log");
    let text = e.data.replace(/\033\[[0-9;]*m/g,"");
    log.innerText += text + "\n";
    log.scrollTop = log.scrollHeight;
};

function sendCmd() {
    let c = document.getElementById("cmd").value;
    if(c) {
        ws.send(c);
        document.getElementById("cmd").value = "";
    }
}

document.getElementById("cmd").addEventListener("keydown", function(e){
    if(e.key === "Enter" && !e.ctrlKey){
        e.preventDefault();
        sendCmd();
    }
});
</script>

</body>
</html>
`)
}

func main() {
	http.HandleFunc("/", page)
	http.HandleFunc("/ws", wsHandler)

	fmt.Println("Server running on :18888")
	err := http.ListenAndServe(":18888", nil)
	if err != nil {
		fmt.Println("Server error:", err)
	}
}
