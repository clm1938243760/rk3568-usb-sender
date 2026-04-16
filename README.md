# RK3568 USB Sender Project

## 项目功能
本项目基于 RK3568 开发板实现 USB U盘镜像检测与自动上传功能。

流程如下：

Windows 写入虚拟U盘
→ 板子检测 ums_shared.img 变化
→ 挂载镜像读取新文件
→ 通过 HTTP 上传到服务器
→ 上传成功后重新绑定 USB

## 文件说明

- `usb_sender.sh`：主发送脚本
- `http_upload_file.py`：HTTP 上传脚本
- `S99usb_sender`：开机自启脚本

## 依赖环境

- Linux 开发板
- Python3
- USB gadget mass storage
- HTTP 文件接收服务器

## 注意事项

- 上传服务器地址、路径、序列号可在脚本中修改
- 若 sender 工作时影响 U盘识别，可增加等待时间和冷静期
