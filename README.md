
## 執行步驟
### 建立空的 mail_notify 專案
#### 開啟VS Code程式，在Termianl底下執行
=>flutter create mail_notify -e

### 在 pubspec.yaml 裏的 dependencies: 下增加幾個相依函式庫

  camera: ^0.10.5+9  # 用於攝像頭功能  
  qr_code_scanner: ^1.0.1  # 用於掃描 QR 碼  
  http: ^1.2.1  # 用於發送 HTTP 請求  
  intl: ^0.19.0  # 用於格式化日期  
  audioplayers: ^6.0.0  # 用於撥放聲音
  
### 同時在 pubspec.yaml 裏的 flutter: 增加 assets: 定義音效檔路徑

flutter:
  assets:
    - assets/sound_effects/
	
### 主程式中，import引用的函式庫

import 'package:flutter/material.dart';  
import 'package:camera/camera.dart'; // 引入 camera 庫以使用相機功能  
import 'package:qr_code_scanner/qr_code_scanner.dart'; // 引入 qr_code_scanner 庫以使用 QR Code 掃描器  
import 'package:http/http.dart' as http; // 引入 http 庫以進行 HTTP 請求  
import 'package:intl/intl.dart';  
import 'package:audioplayers/audioplayers.dart';

### 定義Android權限設定
#### 在檔案 android\app\src\main\AndroidManifest.xml 中的<manifest>標簽底下加入網路使用權限
    <uses-permission android:name="android.permission.INTERNET" />

### 依流程圖撰寫程式
``` mermaid
graph TD
    A([開始]) --> B[開啟攝像頭，並顯示在螢幕上]
    B --> C[1.啟動QR Code模組
    2.偵測區域畫在螢幕中央
    3.提示語顯示在螢幕中央]
    C --> D[QR Code偵測]
    D --> E{QR Code
    與前一次相同}
    E --> |Yes| D
    E --> |No| G{格式正確}
    G --> |Yes| H[Send Line Notify]
    G --> |No| D
    H --> I{傳送成功}
    I --> |Yes| J[顯示戶號]
    I --> |No| K[顯示傳送失敗]
    J --> L[儲存本次R Code]
    K --> L
    L --> D
```


