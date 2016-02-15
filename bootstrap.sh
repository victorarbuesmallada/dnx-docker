#!/bin/bash

echo Running bootstrap.sh
if [ ${DNX_REPOSITORY+x} ]; then

	mkdir -p /opt/dnx_apps
	cd /opt/dnx_apps
	rm -rf ${DNX_REPOSITORY}
	
	echo Clonning repo
	git clone ${DNX_REPOSITORY}	

	# Check for app folder parameter
	if [ ${DNX_FOLDER+x} ]; then

		echo Restoring
		cd ${DNX_FOLDER}
		dnu restore --no-cache
		
		echo Building
		dnu build

		# Check for Environment parameter
		if [ -z ${DNX_ENVIRONMENT+x} ]; then
		  DNX_ENVIRONMENT="web"
		else
		  DNX_ENVIRONMENT="${DNX_ENVIRONMENT}"
		fi

		# Check for Environment parameter
		if [ -z ${DNX_PORT}+x} ]; then
		  DNX_PORT="http://localhost:5000"
		else
		  DNX_PORT="${DNX_PORT}"
		fi

		echo Running
		dnx ${DNX_ENVIRONMENT} --server.urls ${DNX_PORT}

	fi		
	
fi
echo Finished running bootstrap.sh
