# Certbot

## First start

**You will need to add a CNAME record to DNS**

```bash
./first-start.sh [example.com]
```

---

## Renewal certs

**There is no need to add a new DNS record for subsequent certificate
renewal calls for the same domain**

```bash
./start-renew.sh [example.com]
```

---

### Crontab renewal

```bash
crontab -e
```

Add job

```
@monthly ./start-renew.sh [example.com]
```

---

## *Required*

- docker
