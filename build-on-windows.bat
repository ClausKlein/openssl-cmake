@echo ON
set PWD="%cd%"

cd build/src/openssl && C:/Strawberry/perl/bin/perl.exe Configure debug-VC-WIN32 no-comp no-asm no-hw no-krb5 --prefix=/tmp/install && call ms\do_ms.bat && nmake -f ms\nt.mak && nmake -f ms\nt.mak install

cd /tmp/install/lib
cmake -E copy_if_different ssleay32.lib ssleay32d.lib
cmake -E copy_if_different libeay32.lib libeay32d.lib

@echo "renamed debug libs!"
dir
pause

cd %PWD%
cd build/src/openssl && C:/Strawberry/perl/bin/perl.exe Configure VC-WIN32 no-comp no-asm no-hw no-krb5 --prefix=/tmp/install && call ms\do_ms.bat && nmake -f ms\nt.mak && nmake -f ms\nt.mak install

cd %PWD%
