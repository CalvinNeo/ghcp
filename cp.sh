set -o xtrace
cd $PROXY

git fetch tikv_cp $TIKVCOMMIT
git fetch proxy_up $PROXYBRANCH

git branch -D $BRANCH
git reset --hard
git checkout -b $BRANCH proxy_up/$PROXYBRANCH
git cherry-pick $TIKVCOMMIT

ret=$?
set +o xtrace
if [ $ret -ne 0 ]; then
    echo "RESULT> Resolve CONFLICTS"
    exit 1
else
    echo "RESULT> NO CONFLICT"
    exit 0
fi