#!/bin/bash
#
# Copyright (C) 2023 Cesar Augustus Silva
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

: '
The purpose of this script is to migrate website files and database from the
source server to a destination server. Before migration, the script checks if
the dependencies are installed, and if not, installs them automatically.
'

ROOT_DIR=$(pwd)

# Operating system check
if [ "$(uname)" == "Darwin" ]; then
    # Checks if brew is installed
    if ! [ -x "$(command -v brew)" ]; then
        echo "Brew não está instalado. Instalando..."
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        pkg_installer="brew"
    fi
elif [ "$(uname)" == "Linux" ]; then
    sudo="$([ "$(id -u)" = "0" ] && echo "" || echo "sudo")"
    # Check which package manager has installed
    if [ -x "$(command -v yum)" ]; then
        pkg_installer="$sudo yum -y"
        $pkg_installer update
    elif [ -x "$(command -v apt)" ]; then
        pkg_installer="$sudo apt -y"
        $pkg_installer update
    fi
fi

# Installation of dependencies
if [ -n "$pkg_installer" ]; then
    # Checks if wget is installed
    if ! [ -x "$(command -v wget)" ]; then
        echo "Wget não está instalado. Instalando..."
        $pkg_installer wget
    fi
    # Check if jq is installed
    if ! [ -x "$(command -v jq)" ]; then
        echo "JQ não está instalado. Instalando..."
        $pkg_installer jq
    fi
    # Check if ftp is installed
    if ! [ -x "$(command -v ftp)" ]; then
        echo "Ftp não está instalado. Instalando..."
        $pkg_installer ftp
    fi
    # Check if mysql-client is installed
    if ! [ -x "$(command -v mysql)" ]; then
        echo "MySQL não está instalado. Instalando..."
        $pkg_installer mysql-client
    fi
    # Check if zip is installed
    if ! [ -x "$(command -v zip)" ]; then
        echo "Zip não está instalado. Instalando..."
        $pkg_installer zip
    fi
fi

# Name of the JSON file with the list of FTP settings and databases
list_config="configs.json"
if ! [ -e "$list_config" ]; then
    echo -e "O arquivo $list_config não foi encontrado.\n\
Copie o arquivo $list_config.default, renomeie para $list_config\n\
e adicione as configurações para migração do website."
    exit 1
fi

# Loop to read JSON file
while read line; do
    
    ftp_src_host=$(echo $line | jq -r '.ftp.src.host')
    ftp_src_path=$(echo $line | jq -r '.ftp.src.path')
    ftp_src_user=$(echo $line | jq -r '.ftp.src.user')
    ftp_src_pass=$(echo $line | jq -r '.ftp.src.pass')
    
    ftp_dst_host=$(echo $line | jq -r '.ftp.dst.host')
    ftp_dst_path=$(echo $line | jq -r '.ftp.dst.path')
    ftp_dst_user=$(echo $line | jq -r '.ftp.dst.user')
    ftp_dst_pass=$(echo $line | jq -r '.ftp.dst.pass')

    db_src_host=$(echo $line | jq -r '.db.src.host')
    db_src_dbname=$(echo $line | jq -r '.db.src.dbname')
    db_src_user=$(echo $line | jq -r '.db.src.user')
    db_src_pass=$(echo $line | jq -r '.db.src.pass')

    db_dst_host=$(echo $line | jq -r '.db.dst.host')
    db_dst_dbname=$(echo $line | jq -r '.db.dst.dbname')
    db_dst_user=$(echo $line | jq -r '.db.dst.user')
    db_dst_pass=$(echo $line | jq -r '.db.dst.pass')

    if [ -n "$ftp_src_path" ]; then
        if [ "${ftp_src_path: -1}" != "/" ]; then
            ftp_src_path="$ftp_src_path/"
        fi
        if [ "${ftp_src_path:0:1}" == "/" ]; then
            ftp_src_path=$(echo $ftp_src_path | sed 's/^\///')
        fi
    fi
    if [ -n "$ftp_dst_path" ]; then
        if [ "${ftp_dst_path: -1}" != "/" ]; then
            ftp_dst_path="$ftp_dst_path/"
        fi
        if [ "${ftp_dst_path:0:1}" == "/" ]; then
            ftp_dst_path=$(echo $ftp_dst_path | sed 's/^\///')
        fi
    fi

    if [ -n "$ftp_src_user" ] && [ -n "$ftp_src_pass" ] && [ -n "$ftp_src_host" ] &&
        [ -n "$ftp_dst_user" ] && [ -n "$ftp_dst_pass" ] && [ -n "$ftp_dst_host" ]; then

        # Download files from source FTP server
        echo "Baixando os arquivos no ftp://$ftp_src_host/$ftp_src_path..."
        wget -r -l inf --ftp-user=$ftp_src_user --ftp-password=$ftp_src_pass "ftp://$ftp_src_host/$ftp_src_path" -P backup/ -nc -o "wget_$ftp_src_host.log"

        if [ -d "backup/$ftp_src_host/$ftp_src_path" ]; then

            filename_db=$(echo $line | jq -r '.filename_db')
            if [ -n "$filename_db" ]; then
                # Updates the site's database connection files
                search_result=$(find "backup/$ftp_src_host/$ftp_src_path" -iname "$filename_db")
                for file in $search_result; do
                    # Replace old information with new using sed command
                    if [ -n "$db_src_host" ] && [ -n "$db_dst_host" ]; then
                        sed -i.bak "s/$db_src_host/$db_dst_host/g" $file
                    fi
                    if [ -n "$db_src_dbname" ] && [ -n "$db_dst_dbname" ]; then
                        sed -i.bak "s/$db_src_dbname/$db_dst_dbname/g" $file
                    fi
                    if [ -n "$db_src_user" ] && [ -n "$db_dst_user" ]; then
                        sed -i.bak "s/$db_src_user/$db_dst_user/g" $file
                    fi
                    if [ -n "$db_src_pass" ] && [ -n "$db_dst_pass" ]; then
                        db_src_pass2=$(printf '%s' "$db_src_pass" | sed 's/[\/.*()?^$|{}<>;&#%@]/\\&/g')
                        db_dst_pass2=$(printf '%s' "$db_dst_pass" | sed 's/[\/.*()?^$|{}<>;&#%@]/\\&/g')
                        sed -i.bak "s/$db_src_pass2/$db_dst_pass2/g" $file
                    fi
                    rm -f $file.bak
                done
            fi

            # Compress the site backup and send it to the server
            cd "backup/$ftp_src_host/$ftp_src_path"
            zip -r "backup_$ftp_src_host.zip" .
            curl -T "backup_$ftp_src_host.zip" -u "$ftp_dst_user:$ftp_dst_pass" "ftp://$ftp_dst_host/$ftp_dst_path"
            rm -f "backup_$ftp_src_host.zip"
            cd "$ROOT_DIR"

            # Upload unzipper.php to the server and unzip the backup files.
            url_http=$(echo $line | jq -r '.url_http')
            if [ -n "$url_http" ]; then
                curl -T unzipper.php -u "$ftp_dst_user:$ftp_dst_pass" "ftp://$ftp_dst_host/$ftp_dst_path"
                echo "Descompactando o arquivo backup_$ftp_src_host.zip..."
                curl -d "dounzip=true&zipfile=backup_$ftp_src_host.zip" http://$url_http/unzipper.php
            else
                echo "A url_http não foi definida e por isso não foi enviado o unzipper.php para descompactar o arquivo."
            fi
        else
            echo "O site $ftp_src_host não foi encontrado para baixar."
        fi
    else
        echo "Está faltando as configurações dos servidores FTPs."
    fi

    if [ -n "$db_src_host" ] && [ -n "$db_src_dbname" ] && [ -n "$db_src_user" ] && [ -n "$db_src_pass" ] &&
        [ -n "$db_dst_host" ] && [ -n "$db_dst_dbname" ] && [ -n "$db_dst_user" ] && [ -n "$db_dst_pass" ]; then
        # Export source database
        echo "Exportando o banco de dados $db_src_dbname no $db_src_host..."
        mysqldump -u $db_src_user -p$db_src_pass -h "$db_src_host" $db_src_dbname > $db_src_dbname.sql

        # Imports the database on the target
        echo "Importando o banco de dados $db_src_dbname no $db_dst_host..."
        mysql -u $db_dst_user -p$db_dst_pass -h $db_dst_host $db_dst_dbname < $db_src_dbname.sql

        rm $db_src_dbname.sql
    else
        echo "Está faltando as configurações dos bancos de dados MySQL."
    fi
done < <(jq -c '.[]' $list_config)