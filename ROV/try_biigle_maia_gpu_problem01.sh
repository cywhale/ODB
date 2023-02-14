# Kill maia job
curl --insecure -I -X DELETE -u SU@email:TOKEN -H "Accept: application/json" https://localhost:8008/api/v1/maia-jobs/:id
# Kill job instantly ( the Python process is probably killed but this was not propagated back into BIIGLE. In this case, the worker queue timeout will cancel the job after 24 hours.)
# https://github.com/biigle/core/discussions/533
$ docker compose exec worker php artisan tinker
> $job = Biigle\Modules\Maia\MaiaJob::find(JOB_ID)
> $job->delete()

#Problem https://github.com/orgs/biigle/discussions/542#discussioncomment-4924052
docker ps -a #find gpu-worker container
#535e8b969b81   biigle/gpu-worker-dist   "php -d memory_limit…"
sudo docker exec -u 0 -it 535e8b969b81 /bin/sh #-u 0 to get file edit permission
# no vi in this docker, can only use sed
cd /var/www/vendor/biigle/maia/src/resources/scripts/object-detection
sed -i "s/'samples_per_gpu': params\['batch_size'\]/\'samples_per_gpu': int(params\['batch_size'\])/" TrainingRunner.py
cat  # to confirm modification
exit
docker commit 535e8b969b81 biigle/gpu-worker-dist
docker compose up -d


#Problem 1
#DetectionRunner.py: RuntimeError: module compiled against API version 0x10 but this version of numpy is 0xe
#modify FROM tensorflow/tensorflow:latest-gpu (there is no tensorflow:2.5.3-gpu for current MAIA used)
FROM tensorflow/tensorflow:2.6.1-gpu

#Problem 2
#successful NUMA node read from SysFS had negative value (-1), but there must be at least one NUMA node, so returning NUMA node zero
#### Update: cannot apply this, cause NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver. ########
#https://stackoverflow.com/questions/44232898/memoryerror-in-tensorflow-and-successful-numa-node-read-from-sysfs-had-negativ
# 1) Identify the PCI-ID (with domain) of your GPU
#    For example: PCI_ID="0000.81:00.0"
# lspci -D | grep NVIDIA #0000:02:01.0
# 2) Add a crontab for root
# sudo crontab -e
#    Add the following line
# @reboot (echo 0 | tee -a "/sys/bus/pci/devices/0000:02:01.0/numa_node")
######################################################################### Fail trial
