#!/bin/bash

move_files () {
  file=$1
  regex=$2
  if [[ $file =~ $regex ]]
  then
    dir_name="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
    if [ ! -d "$dir_name" ]; then
      echo "Making $dir_name"
      mkdir $dir_name
      chown ftpuser:ftpgroup $dir_name
    fi
    echo "Moving $file to $dir_name"
    cp -r -p $file $dir_name
    rm $file
  fi
}

base_path="/home/pi/FTP"
cd $base_path

# customize directory name list here:
for cam_dir in cam*/
do
  cd $base_path/$cam_dir
  echo $cam_dir
  for f_dir in F*/
  do
    cd $f_dir
    echo $f_dir
    # MDAlarm_20180807-135928.jpg
    cd snap
    echo `pwd`
    files="*.jpg"
    regex="^MDAlarm_([0-9]{4})([0-9]{2})([0-9]{2})-([0-9]{2})([0-9]{2})([0-9]{2})*"
    for file in $files
    do
      move_files $file $regex
    done

    # MDalarm_20180812_100109.mkv
    cd ../record
    echo `pwd`
    files="*.mkv"
    regex="^MDalarm_([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})*"
    for file in $files
    do
      move_files $file $regex
    done
  done
done

# cleanup camera uploads
find /home/pi/FTP/ -type f -mtime +14 -name '*.mkv' -execdir rm -- '{}' \;
find /home/pi/FTP/ -type f -mtime +14 -name '*.jpg' -execdir rm -- '{}' \;
find /home/pi/FTP/ -type d -empty -delete
