#!/bin/bash

MODULE=IOMCore
MODULEDESC="Support libraries for my Perl stuff"

ME=$0
MEFULL=$(readlink -e $ME )
DIRNAME=$(dirname $MEFULL)

(cd $DIRNAME ; git status)
GITAVAIL=$?

if [ $GITAVAIL != 0 ]
then
  echo "The script is not under GIT. Dying"
  exit 1
fi

#MODULErepo=$(cd $DIRNAME ; git remote get-url origin)
MODULErepo=$(cd $DIRNAME ; git remote -v  | grep origin | head -n 1 | awk '{print $2}' )
MODULEbranch=${BRANCH:-master}

WRKDIR=$(mktemp -d)
CHECKOUTDIR=${WRKDIR}/wrk
mkdir -p $CHECKOUTDIR

git clone ${MODULErepo} ${CHECKOUTDIR}
(cd ${CHECKOUTDIR} ; git checkout $MODULEbranch)


PKGVERSION=$(cd $WRKDIR/wrk; perl -e 'use IOMCore_Version q/VERSION/; print ${IOMCore::VERSION}')

GITCOUNT=$(cd ${CHECKOUTDIR} ;git rev-list HEAD --count)
_GIT_COMMIT=$(cd ${CHECKOUTDIR} ;git log -n 1 --pretty=format:"%H")
GITHASH=$(cd ${CHECKOUTDIR} ; git log -n 1 --pretty=format:"%H" | cut -c 1-8)
GITRELEASE="${GITCOUNT}.${MODULEbranch}.${GITHASH}"

TGZDIRNAME="perl-${MODULE}-${PKGVERSION}"

(cd $WRKDIR ; mkdir ${TGZDIRNAME}; cp -r wrk/M* wrk/lib wrk/script $WRKDIR/${TGZDIRNAME} ; tar czvf ${TGZDIRNAME}.tar.gz ${TGZDIRNAME})

cpan2rpm --mk-rpm-dirs ${WRKDIR}
cpan2rpm $WRKDIR/${TGZDIRNAME}.tar.gz --source ${TGZDIRNAME}.tar.gz --no-sign \
--release ${GITRELEASE}  --find-requires --summary ${MODULESUMMARY} \
--author ols@apdo.com --packager "CESOFT Inc."

echo $CHECKOUTDIR
