redis-cli -u "redis://default:ICAdfD6FoQePqoOg1UiwP40sLicNk4xR8vWc2BqZk4M@13.202.109.78:6379"

mongodb://cuddlyAdmindev:SBg7qgcuNwnJqKIQtPutruLQm0RmzpzavJce4ReZf98@13.202.109.78:27017/admin?authSource=admin

scp -i /home/rahul/Downloads/Projects/DST/Cuddly-Duddly/cuddly-duddly-dev.pem -r /home/rahul/Downloads/Projects/DST/Cuddly-Duddly/DevOps ubuntu@13.202.109.78:/home/ubuntu/

rsync -avz -e "ssh -i /home/rahul/Downloads/Projects/DST/Cuddly-Duddly/cuddly-duddly-dev.pem" \
/home/rahul/Downloads/Projects/DST/Cuddly-Duddly/DevOps/ ubuntu@3.110.206.145:/home/ubuntu/DevOps/
