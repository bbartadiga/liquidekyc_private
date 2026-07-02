# LIQUID eKYC Applicant SDK
LIQUID eKYC Applicant SDK版 Android向け (以降、SDK と呼称) のリリース用パッケージです。

当 README は、利用方法の一例を示しております。
具体的な利用方法につきましては、README の内容に照らし合わせ、事業者様の開発環境に応じて、適切にご利用ください。


## 重要事項
* バージョンアップ時には、後述の手順により『LIQUID Portal から取得したすべての aar ファイル』を差し替えてください
* v1.43.0 より、書類ICカードファンクションのOCRによる認証情報入力補助への対応に伴い、以下の依存関係を追加いたしました。詳細は後述の設定方法をご確認ください
  * LiquidPluginMl
  * com.google.mlkit:text-recognition-japanese

### 16KBページサイズ対応について

2025年11月以降、GooglePlay により 64bit CPU に対する 16KBページサイズ対応が義務付けられます

* SDKが依存する一部ライブラリが、x86系アーキテクチャに未対応のため、『SDK取得後 (新規の場合)』にて示した手順により x86 32bit/64bit CPU用のライブラリを除外してください
* v1.42.0 より、16 KB ページサイズに対応した TensorFlow Lite の後継ライブラリ LiteRT へ移行いたしました。
  dependencies にて指定するライブラリを org.tensorflow:tensorflow-lite から com.google.ai.edge.litert:litert に変更いただく必要がございますので、後述の設定方法をご確認ください

## Getting start
* [LIQUID Portal](https://portal.liquidinc.asia/) より SDK(.aarファイル) をお受け取りください。
  * Liquid-?.aar
  * LiquidPluginMl-?.aar
  * itrustekyclibrary.aar　　
  * androidtiffbitmapfactory-?.aar
  * jp2-android-?.aar

  ※?は、バージョン数を表します


### SDK取得後 (新規の場合)
* プロジェクト配下の <app>/libs に LIQUID Portal から取得したすべての aar ファイルを配置します（<app> は、導入先のアプリモジュール名に読み替えてください）

* <app>/build.gradle の android に aaptOptions を定義します　　※ただし Android Gradle プラグインが v4.1 以降の場合は不要

```
aaptOptions {
    noCompress "tflite"
}
```

* <app>/build.gradle の android > defaultConfig > ndk 内の abiFilters について、'arm64-v8a', 'armeabi-v7a を定義します ('x86', 'x86_64' を含めないようにします)

```
ndk {
    abiFilters 'arm64-v8a', 'armeabi-v7a'
}   
```

* <app>/build.gradle の dependencies に依存関係を定義します

```
dependencies {
    implementation 'androidx.appcompat:appcompat:?' // v1.6.1 以上である必要がある。? は導入するファイルのバージョンに置き換え。
    implementation 'androidx.activity:activity-ktx:?' // Kotlin を含む場合: v1.9.3 以上である必要がある。? は導入するファイルのバージョンに置き換え。
    // implementation 'androidx.activity:activity:?' // Java のみの場合: v1.9.3 以上である必要がある。? は導入するファイルのバージョンに置き換え。
    implementation 'com.google.ai.edge.litert:litert:1.4.0'
    implementation 'com.google.mlkit:text-recognition-japanese:16.0.1'
    implementation files('libs/Liquid-?.aar') // ? は導入するファイルのバージョンに置き換え
    implementation files('libs/LiquidPluginMl-?.aar') // ? は導入するファイルのバージョンに置き換え
    implementation files('libs/itrustekyclibrary.aar')
    implementation files('libs/androidtiffbitmapfactory-?.aar') // ? は導入するファイルのバージョンに置き換え
    implementation files('libs/jp2-android-?.aar') // ? は導入するファイルのバージョンに置き換え
}
```


※【参考】build.gradle の全体例

```
plugins {
    id 'com.android.application'
    ・・・
}

android {
    ・・・
    defaultConfig {
        ・・・
        ndk {
            abiFilters 'arm64-v8a', 'armeabi-v7a'
        }    
        ・・・
    }
    ・・・
    aaptOptions {
        noCompress "tflite"
    }
    ・・・    
}

dependencies {
    ・・・
    implementation 'androidx.appcompat:appcompat:?' // v1.6.1 以上である必要がある。? は導入するファイルのバージョンに置き換え。
    implementation 'androidx.activity:activity-ktx:?' // Kotlin を含む場合: v1.9.3 以上である必要がある。? は導入するファイルのバージョンに置き換え。
    // implementation 'androidx.activity:activity:?' // Java のみの場合: v1.9.3 以上である必要がある。? は導入するファイルのバージョンに置き換え。
    implementation 'com.google.ai.edge.litert:litert:1.4.0'
    implementation 'com.google.mlkit:text-recognition-japanese:16.0.1'
    implementation files('libs/Liquid-?.aar') // ? は導入するファイルのバージョンに置き換え
    implementation files('libs/LiquidPluginMl-?.aar') // ? は導入するファイルのバージョンに置き換え
    implementation files('libs/itrustekyclibrary.aar')
    implementation files('libs/androidtiffbitmapfactory-?.aar') // ? は導入するファイルのバージョンに置き換え
    implementation files('libs/jp2-android-?.aar') // ? は導入するファイルのバージョンに置き換え
    ・・・    
}
```


### SDK取得後 (更新の場合)

* プロジェクト配下の <app>/libs から LIQUID eKYC Applicant SDK 導入で追加した aar ファイルを削除します（<app> は、導入先のアプリモジュール名に読み替えてください）

* プロジェクト配下の <app>/libs に LIQUID Portal から取得したすべての aar ファイルを配置します

* <app>/build.gradle の dependencies の依存関係の定義を修正します

```
    implementation files('libs/Liquid-?.aar') // ? は導入するファイルのバージョンに置き換え
    implementation files('libs/LiquidPluginMl-?.aar') // ? は導入するファイルのバージョンに置き換え
    implementation files('libs/itrustekyclibrary.aar')
    implementation files('libs/androidtiffbitmapfactory-?.aar') // ? は導入するファイルのバージョンに置き換え
    implementation files('libs/jp2-android-?.aar') // ? は導入するファイルのバージョンに置き換え
```


## How to use

利用すべきファンクションは、事業者様ごとに異なります。以下に示したすべてを実施いただく必要はございません
詳しくは別冊の『LIQUID eKYC Applicant SDK版仕様書』をご参照ください

* 事前準備
  * 通常は eKYC Connector より認証トークンを取得

  * 評価版時は事前準備不要


* 初期化ファンクション開始
  * 通常は LiquidSdk.getInstance(Context).startVerify(String, String, String) を利用
  
  * 評価版時は LiquidSdk.getInstance(Context).startVerify(String, String, LiquidProcessingResultCallback) を利用

  * ※以後、通常と評価版時との差はありません


* 利用規約ファンクション開始
  * 従来版
    * LiquidSdk.getInstance(Context).showTermsOfUse() を利用
  * クラスファンクション (Activity Result API 対応) 版
    * ShowTermsOfUse.launch() を利用

* 利用規約確認結果の取得・判定等
  * 従来版
    * LiquidSdk.getInstance(Context).handleShowTermsOfUseResult() の引数(LiquidProcessingResultCallback)に渡される結果を利用
  * クラスファンクション (Activity Result API 対応) 版
    * ShowTermsOfUse.register() の引数に渡される結果を利用


* 書類ファンクション開始
  * 従来版
    * LiquidSdk.getInstance(Context).verifyIdDocument() を利用
  * クラスファンクション (Activity Result API 対応) 版
    * VerifyIdDocument.launch() を利用
    
* 書類ファンクション結果の取得・判定等
  * 従来版
    * LiquidSdk.getInstance(Context).handleIdDocumentVerificationResult() の引数(LiquidDocumentVerificationCallback)に渡される結果を利用
  * クラスファンクション (Activity Result API 対応) 版
    * VerifyIdDocument.register() の引数に渡される結果を利用


* 書類ICカードファンクション開始
* ※評価版の場合、運転免許証・在留カード・特別永住者証明書はご利用いただけますが、マイナンバーカードではご利用いただけません
  * 従来版
    * LiquidSdk.getInstance(Context).verifyIdChip() を利用
  * クラスファンクション (Activity Result API 対応) 版
    * VerifyIdChip.launch() を利用
    
* 書類ICカードファンクション結果の取得・判定等
  * 従来版
    * LiquidSdk.getInstance(Context).handleChipVerificationResult() の引数(LiquidChipVerificationCallback)に渡される結果を利用
  * クラスファンクション (Activity Result API 対応) 版
    * VerifyIdChip.register() の引数に渡される結果を利用


* 公的個人認証ファンクション開始
* ※評価版の場合、ご利用いただけません
  * 従来版
    * LiquidSdk.getInstance(Context).identifyIdChip() を利用
  * クラスファンクション (Activity Result API 対応) 版
    * IdentifyIdChip.launch() を利用
    
* 公的個人認証ファンクション結果の取得・判定等
  * 従来版
    * LiquidSdk.getInstance(Context).handleChipIdentificationResult() の引数(LiquidChipIdentificationResult)に渡される結果を利用
  * クラスファンクション (Activity Result API 対応) 版
    * IdentifyIdChip.register() の引数に渡される結果を利用


* 公的個人認証(スマホJPKI)ファンクション開始
  * 従来版
    * LiquidSdk.getInstance(Context).identifyIdMyna() を利用
  * クラスファンクション (Activity Result API 対応) 版
    * IdentifyIdMyna.launch() を利用
    
* 公的個人認証(スマホJPKI)ファンクション結果の取得・判定等
  * 従来版
    * LiquidSdk.getInstance(Context).handleMynaIdentificationResult() の引数(LiquidMynaIdentificationResult)に渡される結果を利用
  * クラスファンクション (Activity Result API 対応) 版
    * IdentifyIdMyna.register() の引数に渡される結果を利用


* 本人容貌ファンクション開始
  * 従来版
    * LiquidSdk.getInstance(Context).verifyFace() を利用
  * クラスファンクション (Activity Result API 対応) 版
    * VerifyFace.launch() を利用

* 本人容貌結果の取得・判定等
  * 従来版
    * LiquidSdk.getInstance(Context).handleFaceVerificationResult() の引数(LiquidFaceVerificationCallback)に渡される結果を利用
  * クラスファンクション (Activity Result API 対応) 版
    * VerifyFace.register() の引数に渡される結果を利用


* アクティベートファンクション開始
  * LiquidSdk.getInstance(Context).activate() を利用

* アクティベート結果の取得・判定等
  * LiquidSdk.getInstance(Context).activate() の引数(LiquidProcessingResultCallback)に渡される結果を利用


※従来版のファンクション開始を利用する場合、各ファンクションの結果を受け取るために、Activity#onActivityResult() を実装してください。onActivityResult() 内で handleShowTermsOfUseResult(), handleIdDocumentVerificationResult(), handleChipVerificationResult(), handleChipIdentificationResult(), handleMynaIdentificationResult(), handleFaceVerificationResult() を呼び出していただくことで、結果を取得いただけます。


```
例）
class MainActivity : AppCompatActivity() {
    ・・・
    private fun startVerify() {
        // 初期化ファンクションの呼び出し例
        LiquidSdk.getInstance(this).startVerify(url, applicantId, token)

        // 評価版時の呼び出し例
        LiquidSdk.getInstance(this).startVerify(url, apiKey) { liquidProcessingResult ->
            when (liquidProcessingResult.result) {
                LiquidProcessingResultStatus.SUCCESS -> {
                    // 正常時の処理
                }
                LiquidProcessingResultStatus.・・・ -> {
                    // 個別にハンドリングしたい「処理結果」返却時の処理
                }
                else -> {
                    // 個別にハンドリングしなかった「処理結果」返却時の処理
                }
            }
        }
    }

    /* 従来版 */
    private fun showTermsOfUse() {
        // 利用規約ファンクションの呼び出し例
        LiquidSdk.getInstance(this).showTermsOfUse(TermsOfUseSettings.Builder().build(), this)
    }
    /* クラスファンクション (Activity Result API 対応) 版 */
    private val showTermsOfUse = ShowTermsOfUse().apply {
        register(this@MainActivity) { result ->
            // handleShowTermsOfUseResult と同様
        }
    }
    private fun launchShowTermsOfUse() {
        // 利用規約クラスファンクションの呼び出し例
        showTermsOfUse.launch(TermsOfUseSettings.Builder().build())
    }

    /* 従来版 */
    private fun verifyIdDocument() {
        // 書類ファンクションの呼び出し例
        LiquidSdk.getInstance(this).verifyIdDocument(
            VerifyIdDocumentParameters.Builder(document, verificationMethod).build(),
            this
        )
    }
    /* クラスファンクション (Activity Result API 対応) 版 */
    private val verifyIdDocument = VerifyIdDocument().apply {
        register(this@MainActivity) { result ->
            // handleIdDocumentVerificationResult と同様
        }
    }
    private fun launchVerifyIdDocument() {
        // 書類クラスファンクションの呼び出し例
        verifyIdDocument.launch(VerifyIdDocumentParameters.Builder(document, verificationMethod).build())
    }

    /* 従来版 */
    private fun verifyIdChip() {
        // 書類ICカードファンクションの呼び出し例
        LiquidSdk.getInstance(this).verifyIdChip(
            VerifyIdChipParameters.Builder(document, verificationMethod).build(),
            this
        )
    }
    /* クラスファンクション (Activity Result API 対応) 版 */
    private val verifyIdChip = VerifyIdChip().apply {
        register(this@MainActivity) { result ->
            // handleChipVerificationResult と同様
        }
    }
    private fun launchVerifyIdChip() {
        // 書類ICカードクラスファンクションの呼び出し例
        verifyIdChip.launch(VerifyIdChipParameters.Builder(document, verificationMethod).build())
    }

    /* 従来版 */
    private fun identifyIdChip() {
        // 公的個人認証ファンクションの呼び出し例
        LiquidSdk.getInstance(this).identifyIdChip(
            IdentifyIdChipParameters.Builder().build(),
            this
        )
    }
    /* クラスファンクション (Activity Result API 対応) 版 */
    private val identifyIdChip = IdentifyIdChip().apply {
        register(this@MainActivity) { result ->
            // handleChipIdentificationResult と同様
        }
    }
    private fun launchIdentifyIdChip() {
        // 公的個人認証クラスファンクションの呼び出し例
        identifyIdChip.launch(IdentifyIdChipParameters.Builder().build())
    }

    /* 従来版 */
    private fun identifyIdMyna() {
        // 公的個人認証(スマホJPKI)ファンクションの呼び出し例
        LiquidSdk.getInstance(this).identifyIdMyna(
            IdentifyIdMynaParameters.Builder().build(),
            this
        )
    }
    /* クラスファンクション (Activity Result API 対応) 版 */
    private val identifyIdMyna = IdentifyIdMyna().apply {
        register(this@MainActivity) { result ->
            // handleMynaIdentificationResult と同様
        }
    }
    private fun launchIdentifyIdMyna() {
        // 公的個人認証(スマホJPKI)クラスファンクションの呼び出し例
        identifyIdMyna.launch(IdentifyIdMynaParameters.Builder().build())
    }

    /* 従来版 */
    private fun verifyFace() {
        // 本人容貌ファンクションの呼び出し例
        LiquidSdk.getInstance(this).verifyFace(
            VerifyFaceParameters.Builder().build(),
            this
        )
    }
    /* クラスファンクション (Activity Result API 対応) 版 */
    private val verifyFace = VerifyFace().apply {
        register(this@MainActivity) { result ->
            // handleFaceVerificationResult と同様
        }
    }
    private fun launchVerifyFace() {
        // 本人容貌クラスファンクションの呼び出し例
        verifyFace.launch(VerifyFaceParameters.Builder().build())
    }

    private fun activate() {
        // アクティベートファンクションの呼び出し例
        LiquidSdk.getInstance(this).activate { liquidProcessingResult ->
            when (liquidProcessingResult.result) {
                LiquidProcessingResultStatus.SUCCESS -> {
                    // 正常時の処理
                }
                LiquidProcessingResultStatus.・・・ -> {
                    // 個別にハンドリングしたい「処理結果」返却時の処理
                }
                else -> {
                    // 個別にハンドリングしなかった「処理結果」返却時の処理
                }
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        // 利用規約ファンクションの結果が onActivityResult() に返った場合、利用規約ファンクション用の結果ハンドリング用メソッドを呼び出す
        LiquidSdk.getInstance(this)
            .handleShowTermsOfUseResult(requestCode, resultCode, data) { liquidProcessingResult ->
                when (liquidProcessingResult.result) {
                    LiquidProcessingResultStatus.SUCCESS -> {
                        // 正常時の処理
                    }
                    LiquidProcessingResultStatus.・・・ -> {
                        // 個別にハンドリングしたい「処理結果」返却時の処理
                    }
                    else -> {
                        // 個別にハンドリングしなかった「処理結果」返却時の処理
                    }
                }
            }

        // 書類ファンクションの結果が onActivityResult() に返った場合、書類ファンクション用の結果ハンドリング用メソッドを呼び出す
        LiquidSdk.getInstance(this)
            .handleIdDocumentVerificationResult(requestCode, resultCode, data) { liquidDocumentVerificationResult ->
                when (liquidDocumentVerificationResult.resultStatus) {
                    DocumentVerificationResultStatus.SUCCESS -> {
                        // 正常時の処理
                    }
                    DocumentVerificationResultStatus.・・・ -> {
                        // 個別にハンドリングしたい「処理結果」返却時の処理
                    }
                    else -> {
                        // 個別にハンドリングしなかった「処理結果」返却時の処理
                    }
                }
            }

        // 書類ICカードファンクションの結果が onActivityResult() に返った場合、書類ICカードファンクション用の結果ハンドリング用メソッドを呼び出す
        LiquidSdk.getInstance(this)
            .handleChipVerificationResult(requestCode, resultCode, data) { liquidChipVerificationResult ->
                when (liquidChipVerificationResult.resultStatus) {
                    ChipVerificationResultStatus.SUCCESS -> {
                        // 正常時の処理
                    }
                    ChipVerificationResultStatus.・・・ -> {
                        // 個別にハンドリングしたい「処理結果」返却時の処理
                    }
                    else -> {
                        // 個別にハンドリングしなかった「処理結果」返却時の処理
                    }
                }
            }

        // 公的個人認証ファンクションの結果が onActivityResult() に返った場合、公的個人認証ファンクション用の結果ハンドリング用メソッドを呼び出す
        LiquidSdk.getInstance(this)
            .handleChipIdentificationResult(requestCode, resultCode, data) { liquidChipIdentificationResult ->
                when (liquidChipIdentificationResult.resultStatus) {
                    ChipIdentificationResultStatus.SUCCESS -> {
                        // 正常時の処理
                    }
                    ChipIdentificationResultStatus.・・・ -> {
                        // 個別にハンドリングしたい「処理結果」返却時の処理
                    }
                    else -> {
                        // 個別にハンドリングしなかった「処理結果」返却時の処理
                    }
                }
            }

        // 公的個人認証(スマホJPKI)ファンクションの結果が onActivityResult() に返った場合、公的個人認証(スマホJPKI)ファンクション用の結果ハンドリング用メソッドを呼び出す
        LiquidSdk.getInstance(this)
            .handleMynaIdentificationResult(requestCode, resultCode, data) { liquidMynaIdentificationResult ->
                when (liquidMynaIdentificationResult.resultStatus) {
                    MynaIdentificationResultStatus.SUCCESS -> {
                        // 正常時の処理
                    }
                    MynaIdentificationResultStatus.・・・ -> {
                        // 個別にハンドリングしたい「処理結果」返却時の処理
                    }
                    else -> {
                        // 個別にハンドリングしなかった「処理結果」返却時の処理
                    }
                }
            }

        // 本人容貌ファンクションの結果が onActivityResult() に返った場合、本人容貌ファンクション用の結果ハンドリング用メソッドを呼び出す
        LiquidSdk.getInstance(this)
            .handleFaceVerificationResult(requestCode, resultCode, data) { liquidFaceVerificationResult ->
                when (liquidFaceVerificationResult.resultStatus) {
                    FaceVerificationResultStatus.SUCCESS -> {
                        // 正常時の処理
                    }
                    FaceVerificationResultStatus.・・・ -> {
                        // 個別にハンドリングしたい「処理結果」返却時の処理
                    }
                    else -> {
                        // 個別にハンドリングしなかった「処理結果」返却時の処理
                    }
                }
            }
    }
   ・・・
}
```

各メソッドの詳細は、SDKと共に提供されている API Documents (Javadoc) をご参照いただけますようよろしくお願いいたします。

各メソッドからどのような「処理結果」が返却されるかについては、『LIQUID eKYC Applicant SDK版インタフェース仕様書(SDK Interface Specifications) 』の "Various process results - Res" シートをご参照いただけますようよろしくお願いいたします。

Activity#onActivityResult() において、結果ハンドリング用メソッド（handle＊＊＊Result()）を適切に呼び分けるか、必ずすべてのファンクション用の結果ハンドリング用メソッドを呼び出すようにするかはお任せいたします
※SDK としては、どのファンクションを実行したかに関わらず、すべてのファンクション用の結果ハンドリング用メソッドを呼び出していただいても差し支えございません。必要な結果ハンドリングのみ実行しコールバックいたします


## Acknowledgments

SDK は以下の OSS を使用しています。ライセンスファイルは別ディレクトリに同梱しております。

* [LiteRT](https://github.com/google-ai-edge/LiteRT.git) [(License)](https://github.com/google-ai-edge/LiteRT/blob/master/LICENSE)
* [JP2ForAndroid](https://github.com/ThalesGroup/JP2ForAndroid.git) [(License)](https://github.com/ThalesGroup/JP2ForAndroid/blob/master/LICENSE)
* [Android-TiffBitmapFactory](https://github.com/Beyka/Android-TiffBitmapFactory.git) [(License)](https://github.com/Beyka/Android-TiffBitmapFactory/blob/master/license.txt)
* [zxing](https://github.com/zxing/zxing.git) [(License)](https://github.com/zxing/zxing/blob/master/LICENSE)
* [zxing-android-embedded](https://github.com/journeyapps/zxing-android-embedded.git) [(License)](https://github.com/journeyapps/zxing-android-embedded/blob/master/COPYING)

SDK におけるチップ読み込みにおいては、サイバートラスト社の iTrust 本人確認サービス を使用しています。

SDK の一部は以下の MLKit Samples を参考にしています。

* [MLKit Samples](https://github.com/googlesamples/mlkit.git) [(License)](https://github.com/googlesamples/mlkit/blob/master/LICENSE)
