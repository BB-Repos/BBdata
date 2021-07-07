#!/bin/bash

while getopts 'g:R:D:L:V:s:f:x:r:e:d:C:c:B:j:u:m:n:a:t:' OPTION; do
    case "${OPTION}" in
        g)
            export gen_call="${OPTARG}" ;;
        R)
            retriever="${OPTARG}" ;;    
        D)
            export DATA_DIR="${OPTARG}" ;;
        L)
            export LOGS_DIR="${OPTARG}" ;;
        V)
            export VID_DIR="${OPTARG}" ;;        
        s)
            split="${OPTARG}" ;;
        f) 
            export num_ts_fields="${OPTARG}" ;; 
        x)
            export cookies="${OPTARG}" ;; 
        r) 
            export frame_rate="${OPTARG}" ;;
        e)
            export shorter_edge="${OPTARG}" ;;  
        d)
            export dataset="${OPTARG}" ;;
        C)
            CONDA_PATH="${OPTARG}" ;;
        c)
            conda_env="${OPTARG}" ;;
        B)  
            download_batch="${OPTARG}" ;;   
        j)
            num_jobs="${OPTARG}" ;;
        u)
            export use_sampler="${OPTARG}" ;;
        m)
            export max_duration="${OPTARG}" ;;
        n)
            export num_samples="${OPTARG}" ;;
        a)
            export sampling="${OPTARG}" ;;
        t)
            export sample_duration="${OPTARG}" ;;
    esac
done

if [ "${conda_env}" != "none" ]; then
    if [ "${CONDA_PATH}" != "none" ]; then
        source "${CONDA_PATH}"
        conda activate "${conda_env}"
    else
        echo "Path to conda package has not been set."
    fi
fi

loader() {
    if [ "${dataset}" == 'sports1m' ]; then
        link="${6}"
        j="${7}"
        if [ "${1}" != "${link}" ]; then
            if [ -f "${VID_DIR}${link}/${5}_${2}.mp4" ]; then
                ln -s \
                "${VID_DIR}${link}/${5}_${2}.mp4" \
                "${VID_DIR}${1}/${5}_${2}.mp4"
                
                return
            fi
        fi
    else
        j="${6}"
    fi

    echo "[${2}]" \
    >> "${LOGS_DIR}errors_j${j}.txt"
    
    youtube-dl \
    -f 'bestvideo[ext=mp4]/best[ext=mp4]' \
    --youtube-skip-dash-manifest \
    -o "${VID_DIR}${1}/${5}_${2}.mp4" \
    --download-archive "${LOGS_DIR}downloaded_j${j}.txt" \
    --external-downloader aria2c \
    --external-downloader-args '-c -j 5 -x 3 -s 5 -k 1M' \
    --cookies "${cookies}" \
    --no-cache-dir \
    -iw \
    "https://www.youtube.com/watch?v=${2}" \
    2>&1 \
    1>/dev/null \
    | tee -a "${LOGS_DIR}errors_j${j}.txt"

    if [ -f "${VID_DIR}${1}/${5}_${2}.mp4" ]; then
        if [ "${use_sampler}" == "True" ]; then
            echo "${VID_DIR}${1}/${5}_${2}.mp4" \
            >> "${DATA_DIR}paths_j${j}.txt"
        fi
    fi
}

streamer() {
    if [ "${dataset}" == 'sports1m' ]; then
        link="${6}"
        j="${7}"
        if [ "${1}" != "${link}" ]; then
            if [ -f "${VID_DIR}${link}/${5}_${2}.mp4" ]; then
                ln -s \
                "${VID_DIR}${link}/${5}_${2}.mp4" \
                "${VID_DIR}${1}/${5}_${2}.mp4"

                return
            fi
        fi
    else
        j="${6}"
    fi

    echo "[${2}]" \
    >> "${LOGS_DIR}errors_j${j}.txt"
    
    youtube-dl \
    -g \
    -f 'bestvideo[ext=mp4]/best[ext=mp4]' \
    --youtube-skip-dash-manifest \
    --cookies "${cookies}" \
    --no-cache-dir \
    -i \
    "https://www.youtube.com/watch?v=${2}" \
    2>&1 \
    1>"${LOGS_DIR}url_j${j}.txt" \
    | tee -a "${LOGS_DIR}errors_j${j}.txt"

    stream=$(head -n 1 "${LOGS_DIR}url_j${j}.txt")

    if [ ! -z "${stream}" ]; then
        ffmpeg \
        -y -hide_banner -loglevel warning \
        -ss "${3}" \
        -t "${4}" \
        -r "${frame_rate}" \
        -i "${stream}" \
        -r "${frame_rate}" \
        -vf scale="if(gt(ih\,iw)\,${shorter_edge}\,-2)":"if(gt(iw\,ih)\,${shorter_edge}\,-2)" \
        "${VID_DIR}${1}/${5}_${2}.mp4" \
        2>&1 \
        | tee -a "${LOGS_DIR}errors_j${j}.txt"
    fi
    if [ -f "${VID_DIR}${1}/${5}_${2}.mp4" ]; then
        if [ "${gen_call}" == "True" ]; then
            ffprobe \
            -v quiet \
            -print_format csv \
            -show_packets \
            "${VID_DIR}${1}/${5}_${2}.mp4" \
            | sed '/audio/d' \
            | grep -v -e '^$' \
            | awk -F, '{ print $4 }' \
            | sort -n \
            | paste -d, -s \
            | awk -v nf="${num_ts_fields}" '{ NF=nf } 1' FS=, OFS=, \
            | awk '{ for (i=2; i<NF; i++) if (!$i) $i="-1" } 1' FS=, OFS=, \
            | awk -F, -v base="${1},${2},${3},${4},${5}," '{ print base,$0 }' \
            | awk 'BEGIN { FS=" "; OFS="" } { $1=$1; print }' \
            >> "${DATA_DIR}timestamps_j${j}.csv"
        fi
        echo "${2}" \
        >> "${LOGS_DIR}downloaded_j${j}.txt"
        
        if [ "${use_sampler}" == "True" ]; then
            echo "${VID_DIR}${1}/${5}_${2}.mp4" \
            >> "${DATA_DIR}paths_j${j}.txt"
        fi
    fi
    rm -rf "${LOGS_DIR}url_j${j}.txt"
}

sampler() {
    vid_len=$( \
    ffprobe \
    -i "${1}" \
    -show_entries format=duration \
    -v quiet \
    -of csv="p=0"\
    )

    if [ ! -z "${vid_len}" ]; then
        if [ "${vid_len%.*}" -le "${max_duration}" ]; then
            sect_len=$(( "${vid_len%.*}"/"${num_samples}" ))
        else
            sect_len=$(( "${max_duration}"/"${num_samples}" ))
        fi
        
        for n in $(seq "${num_samples}"); do
            if [ "${sampling}" == "random" ]; then
                rand_num=$( \
                shuf \
                -i 1-$(( "${sect_len}"-"${sample_duration}" )) \
                -n 1 \
                )                      
                start_time=$(( "${rand_num}"+"${sect_len}"*$(( "${n}"-1 )) ))
            elif [ "${sampling}" == "uniform" ]; then
                start_time=$(( "${sect_len}"*$(( "${n}"-1 )) ))
            else
                echo "unknown"
            fi
            
            ffmpeg \
            -y -hide_banner -loglevel warning \
            -ss "${start_time}" \
            -t "${sample_duration}" \
            -r "${frame_rate}" \
            -i "${1}" \
            -r "${frame_rate}" \
            "${VID_DIR}000/part${start_time}_j${2}.mp4"

            echo "file '${VID_DIR}000/part${start_time}_j${2}.mp4'" \
            >> "${DATA_DIR}concat_j${2}.txt"
        done

        if [ -f "${DATA_DIR}concat_j${2}.txt" ]; then
            ffmpeg \
            -y -hide_banner -loglevel warning \
            -f concat \
            -safe 0 \
            -r "${frame_rate}" \
            -i "${DATA_DIR}concat_j${2}.txt" \
            -r "${frame_rate}" \
            -c copy \
            "${1}"
        fi
        rm -rf "${DATA_DIR}concat_j${2}.txt"
    fi
}

head -n "${download_batch}" "${DATA_DIR}${split}WC.csv" \
> "${DATA_DIR}batch.csv"

if [ "${dataset}" == 'sports1m' ]; then
    columns="{1} {2} {3} {4} {5} {6}"
else
    columns="{1} {2} {3} {4} {5}"
fi

if [ "${retriever}" == "loader" ]; then
    export -f loader
    command="loader ${columns} {%}"
elif [ "${retriever}" == "streamer" ]; then
    export -f streamer 
    command="streamer ${columns} {%}"
fi

n=0
until [ "${n}" -ge 5 ];
do
    # pre-cleanup
    rm -rf "${LOGS_DIR}url_j"* "${LOGS_DIR}downloaded_j"* "${DATA_DIR}paths_j"* \
    "${LOGS_DIR}errors_j"* "${DATA_DIR}timestamps_j"* "${DATA_DIR}concat_j"* \
    "${DATA_DIR}paths.txt"

    echo "$(<"${DATA_DIR}batch.csv")" \
    | parallel \
    --halt now,fail=1 \
    -j"${num_jobs}" \
    --colsep ',' \
    "${command}" \
    || exit 1

    if [ "${use_sampler}" == "True" ]; then
        if ls "${DATA_DIR}paths_j"* 1> /dev/null 2>&1; then
            mkdir -p "${VID_DIR}000/"

            awk 'NF { print }' "${DATA_DIR}paths_j"* \
            >> "${DATA_DIR}paths.txt"

            export -f sampler
            parallel \
            --halt now,fail=1 \
            -j"${num_jobs}" \
            'sampler {} {%}' \
            :::: "${DATA_DIR}paths.txt"
        fi
    fi
    
    grep -qiE "Error in the pull function" "${LOGS_DIR}errors_j"* \
    || break
    grep -qiE "http.cookiejar.LoadError:" "${LOGS_DIR}errors_j"* \
    || break
    grep -qiE "Connection to tcp:" "${LOGS_DIR}errors_j"* \
    || break
   
    n=$((n+1)) 
    sleep 3
done

grep -qiE "HTTP Error [4-5][02-9][0-9]" "${LOGS_DIR}errors_j"* \
&& printf "\nTerminating downloading. Error requires attention.\n" \
&& exit 1 

if ls "${LOGS_DIR}downloaded_j"* 1> /dev/null 2>&1; then
    awk 'NF { print }' "${LOGS_DIR}downloaded_j"* \
    >> "${LOGS_DIR}${split}/downloaded.txt"

    awk -F " " '{ print $NF }' "${LOGS_DIR}${split}/downloaded.txt" \
    > "${LOGS_DIR}downloaded_ids.txt"
    awk -F "," '{ print $2 }' "${DATA_DIR}batch.csv" \
    > "${DATA_DIR}batch_ids.txt"
    grep -Fvxf "${LOGS_DIR}downloaded_ids.txt" "${DATA_DIR}batch_ids.txt" \
    >> "${LOGS_DIR}${split}/failed.txt"
else
    awk -F "," '{ print $2 }' "${DATA_DIR}batch.csv" \
    >> "${LOGS_DIR}${split}/failed.txt"
fi

awk 'NF { print }' "${LOGS_DIR}errors_j"* \
>> "${LOGS_DIR}${split}/errors.txt"

if [ "${retriever}" == "streamer" ]; then
    if ls "${DATA_DIR}timestamps_j"* 1> /dev/null 2>&1; then
        awk 'NF { print }' "${DATA_DIR}timestamps_j"* \
        >> "${DATA_DIR}timestamps.csv"
    fi
fi

grep -Fvxf "${DATA_DIR}batch.csv" "${DATA_DIR}${split}WC.csv" \
> "${DATA_DIR}temp.csv"

cp -f "${DATA_DIR}temp.csv" "${DATA_DIR}${split}WC.csv"

if [ ! -s  "${DATA_DIR}${split}WC.csv" ]; then
    rm -rf "${DATA_DIR}${split}WC.csv"
fi

# post-cleanup
rm -rf "${LOGS_DIR}url_j"* "${LOGS_DIR}downloaded_j"* "${LOGS_DIR}errors_j"* \
"${DATA_DIR}paths_j"* "${DATA_DIR}timestamps_j"* "${DATA_DIR}concat_j"* \
"${DATA_DIR}batch.csv" "${DATA_DIR}temp.csv" "${LOGS_DIR}downloaded_ids.txt" \
"${DATA_DIR}batch_ids.txt" "${DATA_DIR}paths.txt" "${VID_DIR}000/" 






