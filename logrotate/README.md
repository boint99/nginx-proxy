# 🚀 Nginx Log Management & Automation Guide

## 📂 1. Cấu trúc và Vị trí File
| Thành phần | Đường dẫn |
| :--- | :--- |
| **Nginx Config** | `/etc/nginx/nginx.conf` |
| **Logrotate Config** | `/etc/logrotate.d/nginx-logrotate.conf` |
| **Maintenance Script** | `/root/checklog.sh` |
| **Cron Daily** | `/etc/cron.daily/checklog` |
| **Auto Log Output** | `/var/log/checklog_auto.log` |

---

## 🛠 2. Cấu hình Nginx (`nginx.conf`)

Hệ thống sử dụng định dạng log tùy chỉnh để theo dõi hiệu năng của Backend (Upstream).

### 🔹 Log Format
Thêm đoạn mã sau vào trong khối `http { ... }`:
```nginx
log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                '$status $body_bytes_sent "$http_referer" '
                '"$http_user_agent" "$http_x_forwarded_for" '
                '---> Backend: $upstream_addr ($upstream_response_time s)';

access_log /var/log/nginx/access.log main;

## 🛠 3. Phân quyền file
# 1. Phân quyền thư mục Log
chown -R nginx:nginx /var/log/nginx/
chmod 755 /var/log/nginx/
