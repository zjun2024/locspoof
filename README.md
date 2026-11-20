# LocationSpoof
进程内虚拟定位 Tweak —— 钉钉打卡**不触发「虚拟定位检测」提示**。

## 为什么这样设计
- Xunidingwei 是独立 App，走系统 `locationd.simulation` 模拟，会被钉钉检测。
- 本插件是**进程内注入**（MobileSubstrate 注入钉钉），在钉钉进程内构造普通
  CLLocation（无 simulated 标记），钉钉检测失效，打卡无提示。
- 与 zjq1.0 同原理，但更精简。

## 使用
1. 本仓库配置了 GitHub Actions，push 后自动编译出 deb。
2. 在 Actions 页面下载 `locationSpoof-deb` 产物。
3. 用 TrollStore / 巨魔环境安装 / 注入钉钉。
4. 重启钉钉后生效。打卡时即返回你设置的坐标。

## 设置坐标（在 iPhone 上通过 defaults 命令）
```
defaults write com.zjq.locspoof Enabled -bool YES
defaults write com.zjq.locspoof Latitude -float 31.2304
defaults write com.zjq.locspoof Longitude -float 121.4737
defaults write com.zjq.locspoof Altitude -float 10.0
```
默认坐标：杭州西湖 30.2590, 120.1300。
