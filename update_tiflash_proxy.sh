set -o xtrace

# Update raftstore-proxy-6.1
# PROXY_BRANCH=raftstore-proxy-6.1 TIFLASH=~/tiflash/tiflash TIFLASH_BRANCH=release-6.1 PROXY_REMOTE=git@github.com:pingcap/tidb-engine-ext.git PROXY_PR=0 ./update_tiflash_proxy.sh

# Update raftstore-proxy-6.2 to master
# PROXY_BRANCH=raftstore-proxy-6.2 TIFLASH=~/tiflash/tiflash TIFLASH_BRANCH=master PROXY_REMOTE=git@github.com:pingcap/tidb-engine-ext.git PROXY_PR=0 ./update_tiflash_proxy.sh


if [[ -z $PROXY_BRANCH ]]; then
    # raftstore-proxy-x.y
    echo "target proxy branch is not set"
    exit
fi

if [[ -z $TIFLASH ]]; then
    # ~/tiflash/tiflash
    echo "target tiflash dir is not set"
    exit
fi

if [[ -z $TIFLASH_BRANCH ]]; then
    # master
    echo "tiflash branch is not set"
    exit
fi

if [[ -z $PROXY_REMOTE ]]; then
    # git@github.com:pingcap/tidb-engine-ext.git
    echo "proxy remote is not set, should be where the PROXY_BRANCH is"
    exit
fi

if [[ -z $PROXY_PR ]]; then
    echo "proxy pr is not set"
    exit
fi

export PR_TEMPLATE=$TIFLASH/.github/pull_request_template.md

export MAC=0
export SEDSPACE=

if [ "$(uname)" == "Darwin" ]; then
	export MAC=1
	export SEDSPACE=''
fi

echo "Update proxy_up/$PROXY_BRANCH"

cd $TIFLASH
git remote add upstream git@github.com:pingcap/tiflash.git
git fetch upstream $TIFLASH_BRANCH
export B=update_proxy_$TIFLASH_BRANCH_$PROXY_PR_`date +%Y%m%d_%H%M%S`
git checkout -b $B upstream/$TIFLASH_BRANCH
pushd contrib/tiflash-proxy
git remote add proxy_up $PROXY_REMOTE
git fetch proxy_up $PROXY_BRANCH
git checkout proxy_up/$PROXY_BRANCH
popd
git add contrib/tiflash-proxy
git commit -s -m"update tiflash proxy to proxy_up/$PROXY_BRANCH for proxy pr $PROXY_PR"
git push origin $B

export NEW_TEMPLATE=/tmp/pull_request_template$B.md
cp $PR_TEMPLATE $NEW_TEMPLATE
sed -i SEDSPACE 's/close #xxx/ref #4982/g' $NEW_TEMPLATE
export PROXY_PR_URL=https://github.com/pingcap/tidb-engine-ext/pull/$PROXY_PR
sed -i SEDSPACE "s/Summary:/Summary:\n update proxy to proxy_up:$PROXY_BRANCH\n Proxy PR: $PROXY_PR_URL/g" $NEW_TEMPLATE
gh pr create --title "update proxy of $TIFLASH_BRANCH to $PROXY_BRANCH by proxy pr $PROXY_PR" -F $NEW_TEMPLATE --base $TIFLASH_BRANCH 

