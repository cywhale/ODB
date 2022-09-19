#Problem 1
#DetectionRunner.py: RuntimeError: module compiled against API version 0x10 but this version of numpy is 0xe
#modify FROM tensorflow/tensorflow:latest-gpu (there is no tensorflow:2.5.3-gpu for current MAIA used)
FROM tensorflow/tensorflow:2.6.1-gpu

#Problem 2
#successful NUMA node read from SysFS had negative value (-1), but there must be at least one NUMA node, so returning NUMA node zero
#https://stackoverflow.com/questions/44232898/memoryerror-in-tensorflow-and-successful-numa-node-read-from-sysfs-had-negativ
# 1) Identify the PCI-ID (with domain) of your GPU
#    For example: PCI_ID="0000.81:00.0"
lspci -D | grep NVIDIA #0000:02:01.0
# 2) Add a crontab for root
sudo crontab -e
#    Add the following line
@reboot (echo 0 | tee -a "/sys/bus/pci/devices/0000:02:01.0/numa_node")
