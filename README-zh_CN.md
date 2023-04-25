# 海思机顶盒芯片的开源BSP
## 使用方法
1. 提取原厂fastboot
> 详细步骤略

2. 从原厂fastboot中提取专有二进制文件
该项目依赖原厂fastboot中的二进制代码和配置文件，包括`AUXCODE.img, BOOTREG[0-3].bin`，请利用scripts/uboot\_extract.py工具进行提取
```python
python3 scripts/uboot_extract.py -p -d l-loader/bin [path-to-fastboot.bin]
```

3. 开始编译！
```bash
make REC=1
```

4. 将编译得到的文件拷到U盘上

5. 利用scripts/serial\_boot.py或短接usb\_boot，启动到uboot界面

6. 将U盘上的镜像文件写入eMMC中

7. 重启，系统将会启动到主线linux中！

## 参数

1. REC=1, 恢复模式
1. DEBUG=1，调试模式
