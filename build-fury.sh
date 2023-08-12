export PATH="$HOME/proton/bin:$PATH"
SECONDS=0
ZIPNAME="Fury-legacy-KSU-$(date '+%Y%m%d-%H%M').zip"
DEFCONFIG="vendor/fury-ksu_defconfig"

if ! [ -d "$HOME/proton" ]; then
echo "Proton clang not found! Cloning..."
if ! git clone -q https://github.com/kdrag0n/proton-clang --depth=1 --single-branch ~/proton; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

export BUILD_USERNAME=wo1966
export BUILD_HOSTNAME=remix
export KBUILD_BUILD_USER=wo1966
export KBUILD_BUILD_HOST=remix

if [[ $1 = "-r" || $1 = "--regen" ]]; then
make O=out ARCH=arm64 $DEFCONFIG savedefconfig
cp out/defconfig arch/arm64/configs/$DEFCONFIG
echo -e "\nRegened defconfig succesfully!"
exit
fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
echo -e "\nClean build!"
rm -rf out
fi

mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) O=out ARCH=arm64 CC=clang LD=ld.lld AR=llvm-ar AS=llvm-as NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- Image.gz-dtb dtbo.img >> log.txt

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ] && [ -f "out/arch/arm64/boot/dtbo.img" ]; then
echo -e "\nKernel compiled succesfully! Zipping up...\n"
git clone -q https://github.com/Whot1966/AnyKernel3 -b ginkgo/Fury-legacy-KSU
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
cp out/arch/arm64/boot/dtbo.img AnyKernel3
cd AnyKernel3
zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
cd ..
rm -rf AnyKernel3
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo "Zip: $ZIPNAME"
rm -rf out/arch/arm64/boot
else
echo -e "\nCompilation failed!"
fi
