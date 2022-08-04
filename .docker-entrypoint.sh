#!/bin/bash -e

create_docker_properties_file() {
    f=$1
    echo "* Creating $f"
    echo -n > $f

    for line in `env | egrep '^cmsbs'`; do
        value=`echo $line | sed -e 's/\([^=]*\)=\(.*\)/\2/'`
        value=`echo $value | sed -e 's/["\\]/\\\0/g'`
        key=`echo $line | sed -e 's/\([^=]*\)=\(.*\)/\1/'`
        key_subst=`echo $key | sed -e 's/__/./g'`
        echo "$key_subst=\"$value\"" >> $f
    done

    return 0
}

create_docker_properties_file "/UM/cmsbs-conf/docker.properties"

# unzip project ZIP file
# This needs to be done at runtime because the ZIP might contain cmsbs-work/webapps/
# that otherwise would not be overwritten.
set +e
(cd /UM && test -f um-project.zip && unzip -o um-project.zip)
set -e

mkdir -p /UM/cmsbs-work/webapps/ROOT
chown -R um /UM/cmsbs-work

rm -f /UM/cmsbs.pid /UM/cmsbs-conf/conf.d/00_ci.properties

if [ -n "$UM_STARTUP_DELAY" ]; then
    echo "* Waiting for $UM_STARTUP_DELAY seconds"
    sleep $UM_STARTUP_DELAY
fi

cd /UM/scripts
ln -sf /UM/cmsbs-conf/cmsbs.properties

echo "* Running schemaUpdate.sh"
set +e
su um -c "./schemaUpdate.sh cmsbs.properties upgrade"
rc=$?
set -e

if [ $rc == 0 ]; then
    echo "   Schema successfully upgraded."
elif [ $rc == 3 ]; then
    echo "   No schema upgrade needed."
else
    echo "   Schema upgrade failed with exit code: $rc"
fi

if [ -n "$UM_ADMIN_USERNAME" ]; then
    echo "* Creating admin user"
    echo -e "${UM_ADMIN_USERNAME}\n${UM_ADMIN_PASSWORD}\n" | su um -c "./userTool.sh cmsbs.properties -admin"
fi

if [ -z "$@" ]; then
    echo "* Starting UM: $@"
    exec su um -c "./run.sh"
else
    exec $@
fi
