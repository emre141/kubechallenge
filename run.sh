#echo "Updating and installing Docker"
#sudo yum update -y
#sudo yum upgrade -y

#sudo yum remove -y docker \
#    docker-client \
#    docker-client-latest \
#    docker-common \
#    docker-latest \
#    docker-latest-logrotate \
#    docker-logrotate \
#    docker-engine

#sudo yum install -y yum-utils

#sudo yum-config-manager \
#    --add-repo \
#    https://download.docker.com/linux/centos/docker-ce.repo
    
#sudo yum install docker-ce docker-ce-cli containerd.io

#echo "Starting and enabling Docker"
#sudo systemctl start docker
#sudo systemctl enable docker

#!/bin/bash

set -e
set +xv ## Do not remove

info_n() { echo -e "\e[36m$@\e[0m" 1>&2 ; }
info() { echo "" ; info_n $* ; }
warn() { echo ""; echo -e "\e[33m$@\e[0m" 1>&2; }
die() { echo -e "\e[31m$@\e[0m" 1>&2 ; exit 1; }


info_n "############ Constant Varibles #####################"
nodejs_app='nodeapp'
db_instance='postgres'
db_name='sample'
image_name='nodejsapp'
image_tag='v1'
docker_volume='pg-data'
db_port='5432'
app_port='3000'


info_n "#################################### Variable Details ##################################"

info_n "nodejs_app 		  = $nodejs_app"
info_n "db_instance		  = $db_instance"
info_n "db_name			  = $db_name"
info_n "image_name		  = $image_name"
info_n "image_tag		  = $image_tag"
info_n "docker_volume 	          = $docker_volume"
info_n "db_port			  = $db_port"
info_n "app_port		  = $app_port"

info "########################################################################################"

echo "Configure database user"
read -p "Postgres user name: " name
read -s -p "Postgres user password: " password

export POSTGRES_USER=$name
export POSTGRES_PASSWORD=$password

for container in $db_instance $nodejs_app; do
	containerid=$(docker ps -a -q --filter name=$container)

	if [[ $containerid ]]; then
		sudo docker rm --force $containerid || true
	else
		echo -e "Container does not exist \n"
	fi
done

volume=$(docker volume ls  | awk -v volname="$docker_volume" '{if ($2 == volname) print $2;}')
if [[ -z $volume ]]; then
	sudo docker volume create $docker_volume
else
	sudo docker volume rm $volume
	sudo docker volume create $docker_volume
fi

echo -e "========= Remove existing tag =========== \n"
docker rmi $image_name:$image_tag --force
echo -e "==== Build Nodejs Application Image ===== \n"
docker build -t $image_name:$image_tag .

echo "Creating database container (and seed 'sample' database)"
sudo docker run -d \
  --name $db_instance \
  -e POSTGRES_USER=$POSTGRES_USER \
  -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
  -e POSTGRES_DB=$db_name \
  -e PGDATA=/var/lib/postgresql/data/pgdata \
  -v "pg-data:/var/lib/postgresql/data" \
  -p "$db_port:$db_port" \
  --restart always \
  postgres:9.6-alpine

sleep 20 # Ensure enough time for postgres database to initialize and create role

sudo docker exec -i $db_instance psql -U $POSTGRES_USER -d $db_name <<-EOF
create table hello (
  id INT,
  Name TEXT
  );
insert into hello (id, Name ) values (1, 'Hello World' );
EOF


sleep 20 # Wait 20 second before Node application deploy

docker run -d \
	--name $nodejs_app --link $db_instance \
	-p $app_port:$app_port \
  	-e POSTGRES_USER=$POSTGRES_USER \
	-e POSTGRES_HOST=$db_instance  \
	-e DATABASE=$db_name\
  	-e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
	-e PORT=$db_port \
	--restart always \
      	 $image_name:$image_tag

for var in {1..3}; do echo "==== Curl Test===== "; sleep 1; done
curl -w "\n"  http://localhost:3000/hello
