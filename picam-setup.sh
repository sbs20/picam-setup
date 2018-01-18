#!/bin/sh

# picam-setup.sh

# MIT License
# Copyright 2018 Sam Strachan

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# References:     https://github.com/iizukanao/picam

# Hardware:       Raspberry Pi Camera Module V2
#                 Adafruit Mini USB Microphone

# set -x

cd ~
PROG=picam-setup.sh
DEST_DIR=~/picam
SHM_DIR=/run/shm

check_privilege()
{
    root="0"

    if [ "$(sudo id -u)" -ne ${root} ] ; then
        echo "Error: This must be executed with root privileges. Are you a sudoer?"
        exit 1
    fi
}

install_dependencies()
{
    sudo apt-get install -y libharfbuzz0b libfontconfig1
}

make_directories()
{
    mkdir -p $SHM_DIR/rec
    mkdir -p $SHM_DIR/hooks
    mkdir -p $SHM_DIR/state
    mkdir -p $DEST_DIR/archive

    ln -sfn $DEST_DIR/archive $SHM_DIR/rec/archive
    ln -sfn $SHM_DIR/rec $DEST_DIR/rec
    ln -sfn $SHM_DIR/hooks $DEST_DIR/hooks
    ln -sfn $SHM_DIR/state $DEST_DIR/state
}

download_picam()
{
    # Install picam binary
    tmp_file="picam-release.tar.xz"

    api_url="https://api.github.com/repos/iizukanao/picam/releases/latest"
    os_version="jessie"
    if [ "" != "$(cat /etc/os-release | grep stretch)" ]; then
        os_version="stretch"
    fi

    # The release contains a few files. We need to search for the correct one
    # This is the search string
    search="browser_download_url.*binary-${os_version}\.tar"

    # Get the download URL using the search string
    bin_url=$(curl -s ${api_url} | grep ${search} | cut -d '"' -f 4)

    # Download...
    wget -O ${tmp_file} ${bin_url}

    echo "Extract files and remove archive"
    tar -xvf ${tmp_file} && rm ${tmp_file}

    # Work out where we've extracted to...
    #subdir=$(echo ${bin_url} | sed "s:.*\/\(.*\)\.tar\..*:\1:")
    subdir=$(ls | grep picam.*binary)

    echo "Registering binary and removing unnecessary files"
    cp "${subdir}/picam" ${DEST_DIR} && rm -rf ${subdir}
}

install_all()
{
    check_privilege
    install_dependencies
    make_directories
    download_picam

    echo
    echo "Picam installed. Try the following"
    echo "    cd ${DEST_DIR}"
    echo "    ./picam"
    echo "    touch hooks/start_record"
    echo "    touch hooks/stop_record"
    echo 
}

uninstall()
{
    rm -rf ${DEST_DIR}
    rm -rf ${SHM_DIR}/hls
    rm -rf ${SHM_DIR}/hooks
    rm -rf ${SHM_DIR}/rec
    rm -rf ${SHM_DIR}/state

    echo "You may also wish to run:"
    echo "    sudo apt-get purge libharfbuzz0b libfontconfig1"
}

main()
{
    case $1 in
        install)
            install_all
            ;;

        uninstall)
            uninstall
            ;;

        directories)
            make_directories
            ;;

        *)
            echo "Usage ${PROG} {install | uninstall | directories}"
            ;;

    esac
}

main $1
