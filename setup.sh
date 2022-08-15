echo "go to proxy dir" $PROXY
cd $PROXY
git remote add tikv_cp git@github.com:tikv/tikv.git
git remote add proxy_up git@github.com:pingcap/tidb-engine-ext.git
