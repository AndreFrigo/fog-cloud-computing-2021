usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") develop|production update|rollback

This script can be used to update and rollback both deployments of the application.

Example: ./update_app.sh develop update

EOF
  exit
}

build_image() {
    echo "Cloning repository"
    git clone https://github.com/AndreFrigo/fog-cloud-computing-2021-nodejs.git
    cd fog-cloud-computing-2021-nodejs

    echo "Switching to $2 branch"
    git checkout $2

    echo "Building and pushing $1 docker image"
    VERSION=`cat ./app/package.json | jq -r -C .version`
    echo "Working with version $VERSION"
    docker build -t node-server-$1 .
    docker tag node-server-$1 fog2021gr09/vehiclesapp:$1.v.$VERSION
    docker push fog2021gr09/vehiclesapp:$1.v.$VERSION
    echo "Removing repository folder"
    cd ..
    rm -rf fog-cloud-computing-2021-nodejs
}

if [[ $1 = "develop" ]]; then
    NAMESPACE=develop
elif [[ $1 = "production" ]]; then
    NAMESPACE=production
fi

if [[ $2 = "update" ]]; then
    OP=update
elif [[ $2 = "rollback" ]]; then
    OP=rollback
fi

if [[ ! -z $3 ]]; then
    usage
fi


if [[ $NAMESPACE = develop ]] && [[ $OP = update ]]; 
then
    build_image develop develop
    kubectl set image deployment/nodejs-deployment vehiclesapp=fog2021gr09/vehiclesapp:develop.v.$VERSION -n develop
    exit
fi

if [[ $NAMESPACE = develop ]] && [[ $OP = rollback ]]; 
then
    kubectl rollout undo deployment/nodejs-deployment -n develop
    exit
fi

if [[ $NAMESPACE = production ]] && [[ $OP = update ]]; 
then
    build_image prod master
    kubectl set image deployment/nodejs-deployment vehiclesapp=fog2021gr09/vehiclesapp:prod.v.$VERSION -n prod
    exit
fi

if [[ $NAMESPACE = production ]] && [[ $OP = rollback ]]; 
then
    kubectl rollout undo deployment/nodejs-deployment -n prod   
    exit
fi

usage