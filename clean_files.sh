#!/bin/bash

for pid in $(pidof -x clean_files.sh); do
  if [ $pid != $$ ]; then
    echo "[$(date)] : clean_files.sh : Process is already running with PID $pid"
    exit 1
  fi
done

move_files () {
  file=$1
  regex=$2
  if [[ $file =~ $regex ]]
  then
    dir_name="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
    if [ ! -d "$dir_name" ]; then
      mkdir $dir_name
      chown ftpuser:ftpgroup $dir_name
    fi
    cp -r -p $file $dir_name
    rm $file
  fi
}

base_path="/home/pi/FTP"
cd $base_path

# cleanup camera uploads
find $base_path -type f -mtime +14 -name '*.mkv' -execdir rm -- '{}' \;
find $base_path -type f -mtime +14 -name '*.jpg' -execdir rm -- '{}' \;
find $base_path -type f -mtime +14 -name '*.mp4' -execdir rm -- '{}' \;
find $base_path -type f -mtime +14 -name '*.txt' -execdir rm -- '{}' \;
find $base_path -type d -empty -delete

###########################################################
### customize directory name list here for this device: ###
###########################################################
for cam_dir in cam*/
do
  cd $base_path/$cam_dir
  for f_dir in F*/
  do
    cd $base_path/$cam_dir/$f_dir
    # MDAlarm_20180807-135928.jpg
    cd snap
    files="*.jpg"
    regex="^MDAlarm_([0-9]{4})([0-9]{2})([0-9]{2})-([0-9]{2})([0-9]{2})([0-9]{2})*"
    for file in $files
    do
      move_files $file $regex
    done

    # make video from the jpg files
    for date_dir in 20*/
    do
      cd $date_dir
      # remove any 0 byte files:
      find . -name 'MDAlarm*' -size 0 -print0 | xargs -0 rm

      jpg_count=`ls -1 *.jpg 2>/dev/null | wc -l`
      if [ $jpg_count != 0 ] # skip this if no jpg files!
      then
        for jpg_file in *.jpg
        do
          echo "file '$jpg_file'" >> file_list.txt
        done
        if ! cmp file_list.txt file_list_processed.txt >/dev/null 2>&1
        then
          outfile1=`basename $cam_dir`
          outfile2=`basename $date_dir`
          output_filename=$cam_dir_$outfile1"_"$outfile2"_full_jpg.mp4"
          ffmpeg -r 4 -f concat -safe 0 -i file_list.txt -s 1280x720 -vcodec libx264 -crf 25 -pix_fmt yuv420p $output_filename -y
          chown ftpuser:ftpgroup $output_filename
          mv file_list.txt file_list_processed.txt
          chown ftpuser:ftpgroup file_list_processed.txt
        fi
        if [ -f "file_list.txt" ]; then
          rm file_list.txt
        fi
      fi # end skip this if no jpg files!
      cd ..
    done

    # MDalarm_20180812_100109.mkv
    cd ../record
    files="*.mkv"
    regex="^MDalarm_([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})*"
    for file in $files
    do
      move_files $file $regex
    done

    # combine the mkv video files if there are new files
    for date_dir in 20*/
    do
      cd $date_dir
      # remove any 0 byte files:
      find . -name 'MDalarm*' -size 0 -print0 | xargs -0 rm

      mkv_count=`ls -1 *.mkv 2>/dev/null | wc -l`
      if [ $mkv_count != 0 ] # skip this if no mkv files!
      then
        for video_file in *.mkv
        do
          echo "file '$video_file'" >> file_list.txt
        done
        if ! cmp file_list.txt file_list_processed.txt >/dev/null 2>&1
        then
          outfile1=`basename $cam_dir`
          outfile2=`basename $date_dir`
          output_filename=$cam_dir_$outfile1"_"$outfile2"_full.mp4"
          ffmpeg -y -f concat -safe 0 -i file_list.txt -c copy $output_filename -y
          chown ftpuser:ftpgroup $output_filename
          mv file_list.txt file_list_processed.txt
          chown ftpuser:ftpgroup file_list_processed.txt
        fi
        if [ -f "file_list.txt" ]; then
          rm file_list.txt
        fi
      fi # end skip this if no mkv files!
      cd ..
    done

  done
done
