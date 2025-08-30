docker stop $(docker ps -aq)   # stop all containers
docker rm -f $(docker ps -aq) # remove all containers
docker system prune -a --volumes
