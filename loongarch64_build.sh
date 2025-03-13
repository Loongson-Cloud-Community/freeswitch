#!/usr/bin/bash

set -eux;


## 源码编译测试，生成和deb编译相同的modules文件
gen_modules(){
	distro=buster # update as needed
	stable_ver="1.10.7" # update as needed
	ver="$(echo "$stable_ver" | sed -e 's/-/~/g')~n$(date +%Y%m%dT%H%M%SZ)-1~${distro}+1"
	git clean -fdx
	# git reset --hard refs/tags/v${stable_ver}
	./build/set-fs-version.sh "$ver"
	git add configure.ac && git commit -m "bump to custom v$ver"
	(cd debian && ./bootstrap.sh -c $distro -a loongarch64 > /deb.log 2>&1)
	cp debian/modules_.conf /freeswitch-dist/modules.conf
	dch -b -m -v "$ver" --force-distribution -D "unstable" "Custom build."
}


## 更新config文件
update_config(){
	config_guesses=$(find ./ -name '*.guess')
	for guess_file in ${config_guesses}; do
		 curl -sL -o ${guess_file} 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'
		chmod +x ${guess_file}
	done

	
	config_subs=$(find ./ -name '*.sub')
	for sub_file in ${config_subs}; do
		curl -sL -o ${sub_file} 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'
		chmod +x ${sub_file}
	done

}

build_prepare(){
	./bootstrap.sh -j
	rm -rf modules.conf
	cp /freeswitch-dist/modules.conf ./
	update_config
	./configure \
		--prefix=/usr --localstatedir=/var --sysconfdir=/etc \
		--with-gnu-ld --with-python --with-python3 --with-erlang --with-openssl \
		--enable-core-odbc-support --enable-zrtp

}

## 恢复初始状态
reset(){
	git clean -fdx
	git reset --hard 5d26979f03ccc7843e14769fc771ba4a27b9a43c
}

## 生成control文件
gen_control(){
	distro=buster # update as needed
	stable_ver="1.10.7" # update as needed
	ver="$(echo "$stable_ver" | sed -e 's/-/~/g')~n$(date +%Y%m%dT%H%M%SZ)-1~${distro}+1"
	git clean -fdx
	./build/set-fs-version.sh "$ver"
	git add configure.ac && git commit -m "bump to custom v$ver"
	(cd debian && ./bootstrap.sh -c $distro -a loongarch64)

	cp debian/modules_.conf /freeswitch-dist/modules.conf
	dch -b -m -v "$ver" --force-distribution -D "unstable" "Custom build."
}

deb_build(){
	nohup dpkg-buildpackage -b -us -uc -Zxz -z9 > /deb_build.log 2>&1 &
}

eval '$1'
