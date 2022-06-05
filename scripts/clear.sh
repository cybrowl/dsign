# clear all data
# TODO: fix script to accept yes from prompt
yes | dfx deploy snap_images --mode=reinstall
yes | dfx deploy snap --mode=reinstall
yes | dfx deploy snap_main --mode=reinstall
yes | dfx deploy logger --mode=reinstall
echo "done clearing"
