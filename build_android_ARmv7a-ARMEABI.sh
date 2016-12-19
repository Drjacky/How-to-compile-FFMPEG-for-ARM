#!/bin/bash

if [ "$NDK" = "" ]; then
	echo NDK variable not set, assuming ${HOME}/android-ndk
	export NDK=${HOME}/android-ndk
fi

SYSROOT=$NDK/platforms/android-14/arch-arm
WORKING_DIR=`pwd`
# Expand the prebuilt/* path into the correct one
TOOLCHAIN=`echo $NDK/toolchains/arm-linux-androideabi-4.8/prebuilt/linux-x86*`
export PATH=$TOOLCHAIN/bin:$PATH

rm -rf build/ffmpeg
mkdir -p build/ffmpeg
#cd ffmpeg

# Don't build any neon version for now
for version in armv5te armv7a; do

	DEST=$WORKING_DIR/build/ffmpeg
	FLAGS="--target-os=linux --cross-prefix=arm-linux-androideabi- --arch=arm"
	FLAGS="$FLAGS --sysroot=$SYSROOT"
#	FLAGS="$FLAGS --soname-prefix=/data/data/net.sourceforge.servestream/lib/"
	FLAGS="$FLAGS --disable-shared --disable-symver"
	FLAGS="$FLAGS --enable-small"
#	FLAGS="$FLAGS --optimization-flags=-O2"
	FLAGS="$FLAGS --enable-static"
	FLAGS="$FLAGS --disable-doc"
#	FLAGS="$FLAGS --disable-ffmpeg"
#	FLAGS="$FLAGS --disable-ffplay"
#	FLAGS="$FLAGS --disable-ffprobe"
#	FLAGS="$FLAGS --disable-ffserver"
#	FLAGS="$FLAGS --disable-avdevice"
#	FLAGS="$FLAGS --disable-swresample"
#	FLAGS="$FLAGS --disable-postproc"
#	FLAGS="$FLAGS --disable-avfilter"
#	FLAGS="$FLAGS --disable-everything"
#	FLAGS="$FLAGS --disable-gpl"
	FLAGS="$FLAGS --enable-demuxer=aac,flac,h263,h264,m4v,matroska,mp3,mpegvideo,ogg,pcm_alaw,pcm_f32be,pcm_f32le,pcm_f64be,pcm_f64le,pcm_mulaw,pcm_s16be,pcm_s16le,pcm_s24be"
	FLAGS="$FLAGS --enable-demuxer=pcm_s24le,pcm_s32be,pcm_s32le,pcm_s8,pcm_u16be,pcm_u16le,pcm_u24be,pcm_u24le,pcm_u32be,pcm_u32le,pcm_u8,rtp,rtsp,sdp,wav"
	FLAGS="$FLAGS --enable-parser=aac,aac_latm,flac,h263,h264,mpeg4video,mpegaudio,mpegvideo,vorbis,vp8"
	FLAGS="$FLAGS --enable-decoder=aac,aac_latm,flac,h264,mjpeg,mpeg4,mp3,vorbis,wmalossless,wmapro,wmav1,wmav2,wmavoice"
	FLAGS="$FLAGS --enable-encoder=png"
	FLAGS="$FLAGS --enable-protocol=file,http,https,mmsh,mmst"
	FLAGS="$FLAGS --disable-debug"

	case "$version" in
		neon)
			EXTRA_CFLAGS="-march=armv7-a -mfloat-abi=softfp -mfpu=neon"
			EXTRA_LDFLAGS="-Wl,--fix-cortex-a8"
			# Runtime choosing neon vs non-neon requires
			# renamed files
			ABI="armeabi-v7a"
			;;
		armv7a)
			EXTRA_CFLAGS="-march=armv7-a -mfloat-abi=softfp"
			EXTRA_LDFLAGS=""
			ABI="armeabi-v7a"
			;;
		*)
			EXTRA_CFLAGS=""
			EXTRA_LDFLAGS=""
			ABI="armeabi"
			;;
	esac
	DEST="$DEST/$ABI"
	FLAGS="$FLAGS --prefix=$DEST"

	mkdir -p $DEST
	echo $FLAGS --extra-cflags="$EXTRA_CFLAGS" --extra-ldflags="$EXTRA_LDFLAGS" > $DEST/info.txt
	./configure $FLAGS --extra-cflags="$EXTRA_CFLAGS" --extra-ldflags="$EXTRA_LDFLAGS" | tee $DEST/configuration.txt
	[ $PIPESTATUS == 0 ] || exit 1
	make clean
	make -j4 || exit 1
	make install || exit 1

done
