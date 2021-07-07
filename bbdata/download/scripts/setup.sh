#!/bin/bash

while getopts 'D:L:V:d:t:n:i:' OPTION; do
    case "${OPTION}" in
        D)
            DATA_DIR="${OPTARG}" ;;
        L)
            LOGS_DIR="${OPTARG}" ;;
        V)
            VID_DIR="${OPTARG}" ;;
        d)
            dataset="${OPTARG}" ;;
        t)
            toy_set="${OPTARG}" ;;
        n)
            toy_samples="${OPTARG}" ;;
        i)
            time_interval="${OPTARG}" ;;
    esac
done

if [ "${dataset}" == "sports1m" ]; then
    HEADERS="label,youtube_id,start_time,duration,split,link"
else
    HEADERS="label,youtube_id,start_time,duration,split"
fi

declare -a splits=("train" "validate")
for split in "${splits[@]}"; do 
    # preprocess the data files
    if [ "${dataset}" == "hacs" ]; then
        if [ "${split}" == "train" ]; then
            old="training"
        else
            old="validation"
        fi

        grep ",${old}" "${DATA_DIR}${dataset}.csv" \
        | awk -v o=",${old}" -v s=",${split}" '{ gsub( o,s ); print }' \
        | awk -F, -v ti="${time_interval}" '{ print $1,$2,$4,ti,$3 }' OFS="," \
        > "${DATA_DIR}${split}.csv"

        if [ "${split}" == "validate" ]; then
            rm -rf "${DATA_DIR}${dataset}.csv"
        fi
    elif [[ ${dataset} =~ kinetics[1-9]00.* ]]; then
        cp "${DATA_DIR}${split}.csv" "${DATA_DIR}${split}_temp.csv"
        awk -F, -v ti="${time_interval}" \
        '{ print $1,$2,$3,ti,$5 }' OFS="," "${DATA_DIR}${split}_temp.csv" \
        > "${DATA_DIR}${split}.csv"

    elif [[ ${dataset} =~ actnet[1-9]00 ]]; then
        grep ",${split}" "${DATA_DIR}${dataset}.csv" \
        > "${DATA_DIR}${split}.csv"

        if [ "${split}" == "validate" ]; then
            rm -rf "${DATA_DIR}${dataset}.csv" "${DATA_DIR}${dataset}.json"
        fi
    elif [ "${dataset}" == "sports1m" ]; then
        rm -rf "${DATA_DIR}${split}.json" 
    fi

    awk -F "," 'NR>=2 { print }' "${DATA_DIR}${split}.csv" \
    | awk '$1=$1' FS=" " OFS="-" \
    | awk -F "," '{ gsub( /[()]/, "" ); print }' \
    | awk -F "," '{ gsub( "\047" , "" ); print }' \
    | awk '$1=tolower($1)' FS="," OFS="," \
    > "${DATA_DIR}${split}_temp.csv"

    # check for toyset
    if [ "${toy_set}" == "True" ]; then
        awk -v samples="${toy_samples}" '{ print } NR==samples { exit }' \
        "${DATA_DIR}${split}_temp.csv" \
        > "${DATA_DIR}${split}.csv"
    else
        cp -f "${DATA_DIR}${split}_temp.csv" "${DATA_DIR}${split}.csv"
    fi
    rm -rf "${DATA_DIR}${split}_temp.csv"

    # create labels file
    awk -F, '{ print $1 }' "${DATA_DIR}${split}.csv" \
    | sort \
    | uniq \
    >> "${DATA_DIR}labels_temp.txt"

    if [ "${split}" == "validate" ]; then
        sort "${DATA_DIR}labels_temp.txt" \
        | uniq \
        > "${DATA_DIR}labels.txt"

        rm -rf "${DATA_DIR}labels_temp.txt"
    fi
    
    # make working copies and shuffle
    cp "${DATA_DIR}${split}.csv" "${DATA_DIR}${split}WC_temp.csv"
    shuf "${DATA_DIR}${split}WC_temp.csv" \
    > "${DATA_DIR}${split}WC.csv"
    rm -rf "${DATA_DIR}${split}WC_temp.csv"
    
    # add back in headers
    awk -F "," -v headers="${HEADERS}" 'BEGIN { print headers } { print }' \
    "${DATA_DIR}${split}.csv" \
    > "${DATA_DIR}${split}_temp.csv"

    cp -f "${DATA_DIR}${split}_temp.csv" "${DATA_DIR}${split}.csv"

    if [ "${dataset}" == 'sports1m' ]; then
        if [ "${split}" == "validate" ]; then
            mv "${DATA_DIR}${split}.csv" "${DATA_DIR}test.csv"
        fi
    fi
    rm -rf "${DATA_DIR}${split}_temp.csv"

    # create files to be used by downloader.sh
    mkdir "${LOGS_DIR}${split}"
    touch "${LOGS_DIR}${split}/errors.txt" \
    "${LOGS_DIR}${split}/downloaded.txt" \
    "${LOGS_DIR}${split}/failed.txt"
done

# create video directories
mkdir -p "${VID_DIR}"
rm -rf "${VID_DIR}"*

awk -v vid_dir="${VID_DIR}" '$0=vid_dir$0' "${DATA_DIR}labels.txt" \
> "${DATA_DIR}vid_dir_names.txt"

xargs -d '\n' mkdir < "${DATA_DIR}vid_dir_names.txt"

rm -rf "${DATA_DIR}vid_dir_names.txt"







