#!/usr/bin/env bash

# General purpose wrapper around all sorts of dev and troubleshooting tasks.
promo() {(
    set -o errexit
    cd "$PROMO_HOME"

local USAGE="$(cat <<-EOF
usage: promo.sh [ --quiet --verbose --whatif]
   followed by one or more of:
        status
        bounce, bounce.remote
        up, uremote
        down
        log.tail, log.open, log.rm
        status
        db.rebuild, db.rebuild.promo
        gencode, gencode.promo
        compile.java
        build.ui
        test [:codegen :server[:admin :campaign :core :platform :tracking] :tools] TEST
        db.bounce
        db.up
        db.down
        db.tail, db.log
        db.ping, db.status
        db.staging.list, db.staging.setup ID
        db.properties.edit, db.properties.test.copy
        db.key.dev, db.key.prod
        db.mysql
EOF
)"
    [[ ! "$1" ]] && eecho "$USAGE" && return 0

    local LOG_LINES=1000

    local _QUIET=$_QUIET _VERBOSE=$_VERBOSE _WHATIF=$_WHATIF
    [[ "$PWD" != "$PROMO_HOME" ]] && iecho_and_eval "cd $(tilde_compress $PROMO_HOME)"
    shopt -s extglob

    while [[ "$1" ]]; do
        vecho "promo: $1"
        case "$1" in
            status)
                promo db.status
                promo promo.status
                ;;

            b?(ounce).rem?(ote))
                wecho_and_eval "gradle stopTomcat startTomcatRemoteDb"
                ;;
            b?(ounce))
                wecho_and_eval "gradle stopTomcat startTomcatDebug"
                ;;
            up.rem?(ote))
                wecho_and_eval "gradle startTomcatRemoteDb"
                ;;
            up)
                wecho_and_eval "gradle startTomcatDebug"
                ;;
            d?(own))
                wecho_and_eval "gradle stopTomcat"
                ;;
            t?(ail) | log?(.tail))
                iecho "$ tail -n $LOG_LINES -f "$PROMO_LOG""
                wait4file "$PROMO_LOG" 60 2 && tail -n $LOG_LINES -f "$PROMO_LOG"
                ;;
            log.o?(pen) | log.e?(dit))
                wecho_and_eval "subl --project "PROMOLYTICS.sublime-project" "$PROMO_LOG""
                ;;
            log.rm)
                wecho_and_eval "rm -f "$PROMO_LOG""
                ;;
            p.s?(tat?(us)))
                echo "PID: $(pgrep -f "http.port=8080")"
                iecho "$ nc -4 -G 1 -z localhost 8080"
                nc -4 -G 1 -z localhost 8080 || echo "Port 8080 is not listening."
                ;;

            gencode.promo*)
                wecho_and_eval "gradle genCodePromolytics"
                ;;
            gencode)
                wecho_and_eval "gradle genCode"
                ;;

            compile?(.java))
                wecho_and_eval "gradle compileJava"
                ;;

            build.ui) #all but buildCouponUi, due to some gulp error
                wecho_and_eval "gradle buildManufacturerUi buildRetailerUi buildMatrixUi buildPriceUi"
                ;;

            test)
                local test="$2" && shift
                [[ "$test" =~ ^:.+ ]] && local module="$test" && test="$2" && shift
                [[ ! "$test" ]] && eecho "Missing test" && eecho "$USAGE" && return 1
                [[ ! "$module" =~ .+:$ ]] && module="${module}:"
                wecho_and_eval "gradle ${module}test --tests $test"
                ;;

            db.rebuild.promo*) #db.rebuild.promo [promo only]
                wecho_and_eval "gradle stopTomcat rebuildDatabasePromolytics startTomcatDebug seedDataPromolytics"
                ;;
            db.rebuild) #[all schemas]
                wecho_and_eval "gradle stopTomcat rebuildDatabase startTomcatDebug seedData"
                ;;

            db.b?(ounce)) #db.bounce
                wecho_and_eval "brew services restart mysql@5.7"
                ;;
            db.u?(p)) #db.up
                wecho_and_eval "brew services start mysql@5.7"
                ;;
            db.d?(own)) #db.down
                wecho_and_eval  "brew services stop mysql@5.7"
                ;;
            db.t?(ail)|db.log) #db.tail or db.log
                iecho "$ tail -n $LOG_LINES -f "$MYSQL_LOG""
                wait4file "$MYSQL_LOG" 10 1 && tail -n $LOG_LINES -f "$MYSQL_LOG"
                ;;
            db.ping)
                mysql -uroot --password=Promolytics123 promolytics -e 'SELECT 1;' >& /dev/null && echo "Database is responding." || echo "Database is not responding."
                ;;
            db.s?(tat?(us)))
                wecho_and_eval "brew services list | grep 'mysql@5.7'"
                iecho "$ nc -4 -G 1 -z localhost 3306"
                nc -4 -G 1 -z localhost 3306 || echo "Port 3306 is not listening."
                promo db.ping
                ;;
            db.stag?(e)?(ing)?(.list))
                local c="gcloud sql instances list --filter=promolytics-staging --sort-by=name"
                iecho "\$ $c"
                $c | awk '{printf "%-50s %-16s %s\n", $1, $5, $7}'
                ;;
            db.stag?(e)?(ing).setup)
                local id="$2" && shift
                [[ ! "$id" ]] && eecho "Missing id" && eecho "$USAGE" && return 1
                mkdir -pv "$PROMO_HOME/keys/promolytics"
                rm -fv "$PROMO_HOME"/keys/promolytics/*.*
                rm -rfv "$PROMO_HOME"/keys/promolytics/"$id"
                wecho_and_eval "gradle setupStagingDatabaseAccessPromolytics -Pidentifier=$id -PsetupKeystores=true"
                ;;
            db.prop?(ertie)s?(.edit)) #db.properties [edit]
                wecho_and_eval "open -t "$PROMO_DB_PROPERTIES""
                ;;
            db.key?(s))
                wecho_and_eval "cksum server/core/config_key* server/core/src/main/resources/config_key*"
                ;;
            db.key.dev) #copy config key
                wecho_and_eval "cp -pv server/core/config_key_dev server/core/src/main/resources/config_key" | tilde_compress
                ;;
            db.key.prod|db.key.staging) 
                wecho_and_eval "cp -pv server/core/config_key_prod server/core/src/main/resources/config_key" | tilde_compress
                ;;
            db.wh?(ich)) #active db server in database.properties, keys
                echo ""
                _db_which_grep_db_properties 'deploy/promolytics/src/main/webapp/WEB-INF/classes/database.properties'
                echo ""
                _db_which_grep_db_properties '_stage/apache-tomcat-7.0.35/webapps/promolytics/WEB-INF/classes/database.properties'
                echo ""
                _db_which_grep_db_properties 'server/core/src/test/resources/database.properties'
                echo ""
                # 
                iecho '$ ls keys/promolytics'
                CLICOLOR_FORCE=1 ls -ohF keys/promolytics/ | tail -n +2 | awk '{printf "%s %s\t%s\t%s\n", $5, $6, $7, substr($0,index($0,$8))}'
                echo ""
                wecho_and_eval "cksum server/core/config_key* server/core/src/main/resources/config_key*"
                ;;
            db.mysql)
                #wecho_and_eval "mysql -ureadonly -p \"OffTheCurve1!\" -h $(promo_db_host) promolytics \
                wecho_and_eval "mysql -A -uroot --password=$(promo_db_password) -h $(promo_db_host) promolytics \
                    --ssl-ca="keys/promolytics/server-ca.pem" \
                    --ssl-cert="keys/promolytics/client-cert.pem" \
                    --ssl-key="keys/promolytics/client-key.pem""
                ;;

            --verbose | -v)     _VERBOSE=1 && _QUIET= && echo "# Maximum verbosity";;
                        -V)     _VERBOSE=;;
            --quiet | -q)       _QUIET=1 && _VERBOSE=;;
                      -Q)       _QUIET=;;
            --whatif | -w)      _WHATIF=1 && echo "# Whatif/preview enabled";;
                       -W)      _WHATIF=;;
                
            *)
                local msg="promo: $1: invalid command"
                eecho "$msg" && eecho "$USAGE" && return 1
                ;;
        esac
        shift
    done

)}
alias p='promo'
alias p.reload='. ~/bin/promo.sh'

_db_which_grep_db_properties() {
    local pfile="$1"
    [[ -z "$pfile" ]] && eecho "usage: _db_which_grep_db_properties pfile" && return 1
    iecho "$ grep "$pfile" ..."
    egrep '^db(Host|SSL) ?= ?.+$' "$pfile" || true
}

promo_db_host() {
    egrep '^dbHost' "$PROMO_DB_PROPERTIES" | cut -d'=' -f2 | sed 's/ //g'
}
promo_db_password() {
    egrep '^dbPassword' "$PROMO_DB_PROPERTIES" | cut -d'=' -f2 | sed 's/ //g'
}
