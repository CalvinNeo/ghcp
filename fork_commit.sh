
# Use 0f5058ebcc489bc28f997b93765862d79312b5c0 as patch-tikv-6.4
# PROXY=~/merge3/tidb-engine-ext-merge3 TIKV_COMMIT=0f5058ebcc489bc28f997b93765862d79312b5c0 PROXY_REMOTE=git@github.com:pingcap/tidb-engine-ext.git TIKV_REMOTE=git@github.com:tikv/tikv.git TARGET_BRANCH=patch-tikv-6.4 sh fork_commit.sh

if [[ -z $PROXY ]]; then
    # ~/tidb-engine-ext
    echo "source tikv dir is not set"
    exit
fi

if [[ -z $TIKV_COMMIT ]]; then
    # master
    echo "tikv commit is not set"
    exit
fi

if [[ -z $PROXY_REMOTE ]]; then
    # git@github.com:pingcap/tidb-engine-ext.git
    echo "proxy remote is not set, should be where the PROXY_REMOTE is"
    exit
fi

if [[ -z $TIKV_REMOTE ]]; then
    # git@github.com:tikv/tikv.git
    echo "tikv remote is not set, should be where the TIKV_COMMIT is"
    exit
fi

if [[ -z $TARGET_BRANCH ]]; then
    # patch-tikv-x.y
    echo "target proxy branch is not set"
    exit
fi

cd $PROXY
git remote add tikv_up $TIKV_REMOTE
git remote add proxy_up $PROXY_REMOTE
git fetch tikv_up $TIKV_COMMIT
git checkout -b $TARGET_BRANCH $TIKV_COMMIT

# May do some modification ...

git push $PROXY_REMOTE $TARGET_BRANCH:$TARGET_BRANCH
