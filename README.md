# wrapper-amdl
攒来自用的一个docker镜像  
说明：  
- 镜像基底：gpac/ubuntu  
- wrapper来源：<https://github.com/zhaarey/wrapper> ；未作改动  
- apple-music-downloader 来源：<https://github.com/zhaarey/apple-music-downloader> ；未作改动  
- mp4decrypt来源：<https://www.bok.net/Bento4/binaries/Bento4-SDK-1-6-0-641.x86_64-unknown-linux.zip> ;未作mp4decrypt的自动获取新版本，有需求的可自行fork修改action。
已安装screen  

使用简易说明：  
- 1、建议使用compose方式管理，cli方式也可以，但是需要自己管理路径，以下说明均安装compose方式；  
- 2、建立项目compose目录，例如：  
  - /docker/wrapper-amd1/  
              ├── amd1/  
              ├── data/  
              └── docker-compose.yml  
- 3、第一次wrapper登录，参照原方式：  
  - 3.1 cd /docker/wrapper-amd1 进入compose所在目录；  
  - 3.2.0 如果有2FA，需要新开一个ssh窗口，cd /docker/wrapper-amd1 后输入echo -n 123456 > ./data/2fa.txt 预备，123456修改为2FA验证码，获取后回车确定即可，若无2FA，则跳过此步；  
  - 3.2.1 运行 docker run -v ./data:/app/rootfs/data -e args="-L username:password -F" --rm chaslllll/wrapper-amdl:latest  ；username和password替换为自己id；正常情况下会自动拉取镜像，如果没有自动拉取镜像，可以用docker pull chaslllll/wrapper-amdl:latest 拉取。运行后会显示wrapper的登录情况，如有2FA，按3.2.0操作，登录成功后ctrl+c退出即可；  
  - 3.2.2 运行docker compose up -d正常运行容器，cli命令也可但是注意修改路径映射  
  - 3.3 需要下载时运行 docker exec -it wrapper bash进入容器动态执行命令，wrapper为容器名，compose内已指定为wrapper，cli下需自行指定；  
  - 3.3.1 下载命令为 dl url，dl为源项目自动编译的二进制文件，并做了全局，此处需要注意的是镜像默认的工作路径是/app，所以amdl的config文件需映射到/app，否则会提示缺少config，而且如果docker exec进入后自己修改了当前工作路径的话，需要cd到/app后使用dl才能正确找到config；  
- 4、使用screen 将下载后台运行，此时可以推出docker exec 而且可以断开ssh
 
本简易说明只针对技术小白，大佬们请自行修改使用  

截至更新时只测试了下载过程，因为data是直接拷贝过来的，并未测试登录过程  
