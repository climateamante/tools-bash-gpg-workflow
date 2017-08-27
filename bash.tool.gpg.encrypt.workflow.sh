#!/bin/sh
# created: 08-22-2017
# updated: 08-27-2017
# name: ssh_helper.sh
# about: encryption backup workflow
# version: 0.1.0

function ui_get_local_folder() {

read -r -d '' applescript_get_folder_path << EOF
   set var_folder to POSIX path of (choose folder with prompt "Choose Folder To Sync")
   return POSIX path of var_folder
EOF

local folder_path=$( osascript -e "$applescript_get_folder_path" )

echo "${folder_path}"

}

function ui_get_password() {

read -r -d '' applescript_get_password << EOF
   set var_password to the text returned of (display dialog "Enter GPG Password" default answer "")
   return var_password
EOF

local user_password=$( osascript -e "$applescript_get_password" )

echo "${user_password}"

}

function current_timestamp (){
    echo $(date "+%Y.%m.%d.%H%M%S")
}

function get_random_alphanum() {


local python_get_random_alphanum=$(
python - <<EOF
from random import choice;
print ''.join([
    choice(
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    'abcdefghijklmnopqrstuvwxyz'
    '0123456789')
    for i in range(10000)])
EOF
)


    # trim length to thirty character file name or user input amount
    local alphanum_length=${1}
    local alphanum_filename=$( \
    echo "${python_get_random_alphanum}" | \
    head -c "${alphanum_length}" \
    )

    echo "${alphanum_filename}"

}


function create_temp_file () {

    local temp_file=$( \
    mktemp /tmp/bash.script.temp.gpg.workflow.XXXXXXXXXX || \
    exit 1 )

    echo "${temp_file}"
}


function gpg_workflow () {

    # set working directory
    local work_directory=$( ui_get_local_folder )
    cd "${work_directory}"
    pwd

    # prompt for user password | will be applied to all files
    local user_password=$( ui_get_password )



    # create csvfile and headers
    local csv_file=$( create_temp_file )
    local timestamp=$( current_timestamp )
    local csv_filename="file.list.${timestamp}.csv"


    echo "file,id" >> ${csv_file}


    # create tar and gpg output folder

    for i in *; do
        local original_file=${i}
        local file_id=$( get_random_alphanum 30 )
        local current_file=${i}
        local tar_file="archive.${file_id}.tar"

        echo "${original_file},${file_id}" >> ${csv_file}

        echo ${tar_file}

        tar -cf "${tar_file}" "${original_file}"
        echo "${user_password}" | \
        gpg --passphrase-fd 0 \
        -c "${tar_file}"

    done

    mkdir output
    local output_folder="$(pwd)/output/"


    rm -rf *.tar
    mv *.gpg "${output_folder}"


    mv ${csv_file} "$(pwd)/${csv_filename}"
    rm -rf "${csv_file}"

}

echo $( gpg_workflow )