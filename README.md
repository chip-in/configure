# configure
Configuration tool for chip-in core node system

# 概要
configure は以下の機能を持つ。
* core ノードのコンテナの生成（run）時にconsul の設定ファイルを生成する
* core ノードのコンテナの起動（run/startt）時に nginx, shibboleth, moquitto の設定ファイルを生成する
* コアレジストリ（＝ consul kvs）の値が変更された場合、これを反映して、nginx, shibboleth,mosquitto を reload/restart する。
* core ノードのコンテナの生成（run）時に必要に応じて、 Let's Encript の certbot を起動し、自動更新（certbot renew）バッチをセットアップする

# consul の設定ファイル
consul の設定ファイルは環境変数を参照して /etc/consul.conf として作成される。以下の環境変数を参照する。

|変数名|必須|説明|
----|----|----
|PEERS|no|他のコアノードのIPアドレスのリスト（カンマ区切り）|
|CONSUL_SHARED_KEY|no| consul のクラスタ通信における共有鍵を指定する|

# nginx の設定ファイル
nginxでは、コアノードサーバとJWT発行サーバの2つの仮想サーバが設定される。

## コアノードサーバ
コアノードの機能を実装する HMR, mosquitto へのリバースプロキシである。/etc/nginx/conf.d/default.conf に仮想サーバが定義されており、以下の環境変数を参照する。

|変数名|必須|説明|
----|----|----
|CORE_FQDN|yes|コアノードのFQDN。省略すると server_name は localhost となる|

また、以下の設定ファイルがあればそれを参照する。

|パス|説明|
----|----
|/etc/nginx/conf.d/auth.conf.proxy| 各プロキシ設定に JWT認証設定を読み込みJWTを持っていないアクセスを拒否する|

### JWT 認証設定
KVSにキーJwt が設定されている場合、coreノードへのアクセスには jwt 認証が設定される。具体的には、JWT認証設定（/etc/nginx/chip-in.jwt.settings/jwtVerifier.json）を生成し、このJWT認証設定を参照して JWT 認証を行う nginx の設定ファイルを /etc/nginx/conf.d/auth.conf.proxyに生成する。以下のKVS上の以下の値を参照する。

|変数名|必須|説明|
----|----|----
|sharedKey|yes|JWT用共有鍵|

## JWT発行サーバ
JWTの発行を受け持つサーバである。/etc/nginx/conf.d/jwtIssuer.conf に仮想サーバが定義されており、以下の環境変数を参照する。キー jwt が存在しない場合は、設定ファイルは空となる。

|変数名|必須|説明|
----|----|----
|JWT_ISSUER_FQDN|no|JWT発行サーバのFQDN。省略するとJWT発行サーバの内容は空となる。|
|JWT_ISSUER_HTPASSWD|no|basic 認証を行う場合のHTPASSWDのエントリ行をカンマで区切って結合した文字列で指定する|

JWT発行サーバは basic 認証による認証を行うが、KVSに idps/:idp にマッチするキーが設定されている場合、SAML 認証設定を生成する。

### JWT 発行設定
JWT発行設定（/etc/nginx/chip-in.jwt.settings/jwtIssuer.json）を生成する。KVS上のキー/jwtに対応する値を参照する。キーが存在しない場合は、JWT発行設定には空のファイルが生成される。

|JSON属性|説明|
----|----
|.sharedKey|JWT用共有鍵が指定されていなければならない|
|expSec|発行するJWTの有効期限（単位：秒）が指定されていなければならない|
|attrs|HTTPヘッダー値をコピーして作成するJWT属性の属性名の配列|
|uriPattern|認証に成功したときのリダイレクト先として指定されているURLに許可されるパターン|

# サーバ証明書
サーバ証明書は mod_ssl でインストールされる自己証明書か Let's encrypt から取得する証明書のいずれかを利用できる。
* 環境変数 CERTIFICATE_MODE に 'selfsigned' が指定されている場合は、/etc/pki/tls/certs/localhost.crt が利用される。 
* 環境変数 CERTIFICATE_MODE に 'certbot' が指定されている場合は、Let's encrypt からサーバ証明書の取得を試みる。この場合、Let's encrypt のアカウントに付与するメールアドレスを環境変数 LETS_ENCRYPT_EMAIL に指定しなければならない。環境変数 JWT_ISSURE_FQDN が指定されている場合は、証明書の SAN に当該FQDNを加えることで JWT 発行サーバの証明書としても利用できるものを取得する。初回起動時にサーバ証明書の取得に成功すると、certbot を毎夜 AM 1:00 にサーバ証明書更新を試みるバッチが有効となる。
* 環境変数 CERTIFICATE_MODE が指定されていない場合、SSL 通信を行わない。

# SAML認証設定
shibboleth のメタデータと属性の設定をKVSの内容に従って設定する。

## メタデータの設定
KVS 上のキー metadatas/ _:key_  の内容に沿ってメタデータを設定できる。

|項目名|説明|
----|----
|url |/etc/shibboleth/shibboleth2.xml 内の MetadataProvider 要素のurl 属性の値となり、当該URLからダウンロードする設定となる。この場合、backingFilePath属性はmetadata/ _:key_ .xmlとなる。この値が設定されていない場合は、file属性に metadata/ _:key_ .xml に設定する。|
|metadata|メタデータのXMLを設定する。設定した値がmetadata/ _:key_ .xmlにダウンロードされる。|

url も metadata も指定されていない場合、コンテナの /etc/shibboleth/metadata をマウントし、shibboleth から metadata/ _:key_ .xml でメタデータを参照できるようにしなければならない。

## IdP の設定
KVS 上のキー idps  の値から SAML  IdP との連携を設定できる。
キー idps の値には、 SAML IdP の entity ID のリストを保持しなければならない。/etc/shibboleth/shibboleth2.xml 内にリストの個数分のSSO要素を生成し、その entityId 属性にそれぞれの entity IDを付与する。

## 属性の設定
キー attributes/_:name_ に属性のリストを保持しなければならない。/etc/shibboleth/shibboleth2.xml 内のリストの個数分のAttribute要素を生成し、その name 属性には、属性名 _:name_ を設定する。

|項目名|説明|
----|----
|source|SAMLアサーション上の属性名を指定する。Attribute要素の id 属性に展開される。|
|type|属性のタイプ。通常は StringAttributeDecoder を指定する。|

## entity ID と SP メタデータ
SAML SP のエンティティID（=メタデータのダウンロードURL）は以下の通りとなる。
```
https:// _FQDN_ /Shibboleth.sso/Metadata
```
ここで、 _FQDN_ には環境変数 JWT_ISSUER_FQDN の値が設定される。

# ログ収集サーバ
環境変数 LOG_SERVER_URL が設定されている場合、/l ロケーションへの http リクエストをそのURLにプロキシ転送する。

# mosquitto の設定ファイル
mosqitto の ACL を設定する（未設計/未実装）

# core ノード起動後のKVSへの設定のアップロード
（未設計/未実装）

# jwt 発行コマンド
（未設計/未実装）

