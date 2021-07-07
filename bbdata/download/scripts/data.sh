#!/bin/bash

while getopts 'g:r:D:L:T:R:u:l:d:' OPTION; do
    case "${OPTION}" in
        g)
            gen_call="${OPTARG}" ;;
        r)
            use_records="${OPTARG}" ;;
        D)
            DATA_DIR="${OPTARG}" ;;
        L)
            LOGS_DIR="${OPTARG}" ;;
        T)
            TFDS_DIR="${OPTARG}" ;;
        R)
            RECORDS_DIR="${OPTARG}" ;;
        u)
            data_url="${OPTARG}" ;;
        l)
            labels_url="${OPTARG}" ;;
        d)
            dataset="${OPTARG}" ;;
    esac
done

mkdir -p "${LOGS_DIR}" "${DATA_DIR}"

if [ "${gen_call}" == "True" ]; then
    mkdir -p "${TFDS_DIR}"
fi

if [ "${use_records}" == "True" ]; then
    mkdir -p "${RECORDS_DIR}"
fi

rm -rf "${LOGS_DIR}"* "${DATA_DIR}"* "${TFDS_DIR}"* "${RECORDS_DIR}"*

if [ "${dataset}" == "hacs" ]; then
    wget -q -O "${DATA_DIR}${dataset}.zip" "${data_url}"
    unzip "${DATA_DIR}${dataset}.zip" -d "${DATA_DIR}"
    rm -rf "${DATA_DIR}${dataset}.zip"
    mv "${DATA_DIR}${dataset}_"* "${DATA_DIR}${dataset}"

    awk '!/,testing/' "${DATA_DIR}${dataset}/${dataset}_clips"* \
    > "${DATA_DIR}${dataset}.csv"
    rm -rf "${DATA_DIR}${dataset}/"

elif [[ ${dataset} =~ kinetics[1-9]00.* ]]; then
    wget -q -O "${DATA_DIR}${dataset}.tar.gz" "${data_url}"
    tar -xzf "${DATA_DIR}${dataset}.tar.gz" -C "${DATA_DIR}"
    mv "${DATA_DIR}${dataset}/train.csv" "${DATA_DIR}${dataset}/validate.csv" "${DATA_DIR}"
    rm -rf "${DATA_DIR}${dataset}/" "${DATA_DIR}${dataset}.tar.gz"

elif [[ ${dataset} =~ actnet[1-9]00 ]]; then
    wget -q -O "${DATA_DIR}${dataset}.json" "${data_url}"
    
elif [ "${dataset}" == "sports1m" ]; then
    wget -q -O "${DATA_DIR}${dataset}.zip" "${data_url}"
    unzip "${DATA_DIR}${dataset}.zip" -d "${DATA_DIR}"
    rm -rf "${DATA_DIR}${dataset}.zip"
    mv "${DATA_DIR}sports1m_test.json" "${DATA_DIR}validate.json"
    mv "${DATA_DIR}sports1m_train.json" "${DATA_DIR}train.json"

    wget -q -O "${DATA_DIR}labels.txt" "${labels_url}"
fi








