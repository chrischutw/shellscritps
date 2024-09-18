# Shell Scripts Project

此專是一套 Shell Script 的腳本集合，並將功能與主邏輯分離，以便更好的維護和擴展。專案結構如下所示：

```shell
shellscripts/
├── gcp
│   ├── certificate
│   │   ├── certificate_rotate.sh
│   ├── cloudrun
│   │   ├── add_cloudrun_to_lb.sh
│   │   ├── replace_cloudrun_from_lb.sh
│   └── dns
│       └── add_recordsets.sh
├── incl.sh
├── lib
│   ├── certificate_functions.sh
│   ├── cloudrun_functions.sh
│   ├── dns_functions.sh
│   └── glb_functions.sh
├── README.md
└── ssl
    ├── prepare_crt.sh
```

## 檔案說明

### `gcp/`

- 此目錄包含與 GCP 操作相關的主要功能 (main function)，目前依據功能進一步分類為 `certificate`, `cloudrun` 及 `DNS`。

#### `gcp/certificate/`

- **`certificate_rotate.sh`**: 用來更新 Google Cloud Load Balancer (GLB) 上的憑證。此腳本主要功能是自動化憑證輪替。

#### `gcp/cloudrun/`

- **`add_cloudrun_to_lb.sh`**: 用來將新的 Cloud Run 服務新增至 Load Balancer 中。
- **`replace_cloudrun_from_lb.sh`**: 替換現有 Load Balancer 中的 Cloud Run 服務。

#### `gcp/dns/`

- **`add_recordsets.sh`**: 用來新增 Cloud DNS 的 recordset。此腳本主要功能是自動化管理 DNS 記錄。

### `incl.sh`

- **`incl.sh`**: 用來 include 位於 `lib` 目錄下的所有 function。此腳本負責將功能模組引入至主腳本中。

### `lib/`

- 此目錄下的腳本包含與特定功能相關的子函數，所有腳本皆為 library，不包含主功能 (main function)。

#### `certificate_functions.sh`

- 包含與 SSL 憑證相關的輔助函數，主要用於 `ssl/` 中。

#### `cloudrun_functions.sh`

- 包含與 Cloud Run 操作相關的輔助函數，主要用於 `gcp/cloudrun` 目錄下的腳本。

#### `dns_functions.sh`

- 包含與 Cloud DNS 操作相關的輔助函數，主要用於 `gcp/dns/` 中。

#### `glb_functions.sh`

- 包含與 Google Cloud Load Balancer 操作相關的輔助函數，主要用於 `gcp/certificate/` 中。

### `ssl/`

- 此目錄包含與 SSL 憑證處理相關的腳本。

#### `prepare_crt.sh`

- 用來準備 SSL 憑證，執行與憑證生成、格式處理等相關的自動化操作。此腳本使用 `lib/certificate_functions.sh` 中的函數。

## 其他說明

- 各個腳本的具體使用方式與範例，請參考腳本中的內部說明與註解。每個腳本皆有詳細的操作流程記載。

## Formatting Variables

```shell
\$([a-zA-Z_][a-zA-Z0-9_]*)
"${$1}"
```
