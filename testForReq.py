import requests
import uuid
import time
import codecs
import random
from hashlib import md5

X_RPC_client_type = 2  # 类型
X_RPC_sys_version = 14
X_RPC_channel = "Xiaomi"
X_RPC_device_name = "Xiaomi M2101K9C"
X_RPC_device_model = "2304FPN6DC"
X_RPC_device_fp = ""
X_RPC_app_id = "bll8iq97cem8"
X_RPC_verify_key = ""
X_RPC_device_id = "515533a6-bb88-4215-aa64-939976cc54ef"
X_Requested_With = "com.mihoyo.hyperion"
timestamp_ms = int(time.time() * 1000)

## For DS

## 这里的地方就不要动了，当常量salt用
X_RPC_APP_VER = "2.71.1"
SALT_K2 = "rtvTthKxEyreVXQCnhluFgLXPOFKPHlA"
SALT_LK2 = "EJncUPGnOHajenjLhBOsdpwEMZmiCmQX"
SALT_4X = "xV8v4Qu54lUKrEYFZkJhB8cuOh9Asafs"
SALT_6X = "t0qEgfub6cvueAPgR5m9aQWWVciEer7v"

# body和query一般来说不会同时存在
# 可以使用json库的dumps函数将对象转为JSON字符串
# body = json.dumps({"role": "123456789"}, sort_keys=True)
body = ""
# 可以使用urllib中的parse库的urlparse函数，传入URL，得到返回值中的query字段。
# 将其转为列表（通过str.split("&")），通过sorted函数来排序，再用"&".join来将其转为最终值
query = "&".join(sorted("".split("&")))


# ds2 Salt一般用在查询具体游戏账号信息（比如崩铁、原神具体信息时）
def return_ds2():
    current_time = int(time.time())
    random_num = random.randint(100000, 200000)
    if random_num == 100000:
        random_num = 642367
    # 也可以直接用更简单粗暴的方法
    # r = random.randint(100001, 200000)
    main = f"salt={SALT_4X}&t={current_time}&r={random_num}&b={body}&q={query}"
    ds = md5(main.encode(encoding="UTF-8")).hexdigest()

    return f"{current_time},{random_num},{ds}"  # 最终结果


print(return_ds2())


# ds1 Salt用在和米游社相关操作的时候
def return_ds1():
    lettersAndNumbers = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

    salt = SALT_K2

    t = int(time.time())
    r = "".join(random.choices(lettersAndNumbers, k=6))
    main = f"salt={salt}&t={t}&r={r}"
    ds = md5(main.encode(encoding="UTF-8")).hexdigest()

    return f"{t},{r},{ds}"  # 最终结果。


print(return_ds1())

# url = "https://httpbin.org/post"
# payload = {}

# response = requests.post(url, data=payload)

# # 打印响应状态码和内容
# print(f"Status Code: {response.status_code}")
# print(f"Response Body: {response.text}")


def get_fp():
    url = "https://public-data-api.mihoyo.com/device-fp/api/getFp"

    ext_fields = r'{"ramCapacity":"3746","hasVpn":"0","proxyStatus":"0","screenBrightness":"0.550","packageName":"com.miHoYo.mhybbs","romRemain":"100513","deviceName":"iPhone","isJailBreak":"0","magnetometer":"-160.495300x-206.488358x58.534348","buildTime":"1706406805675","ramRemain":"97","accelerometer":"-0.419876x-0.748367x-0.508057","cpuCores":"6","cpuType":"CPU_TYPE_ARM64","packageVersion":"2.20.1","gyroscope":"0.133974x-0.051780x-0.062961","batteryStatus":"45","appUpdateTimeDiff":"1707130080397","appMemory":"57","screenSize":"414×896","vendor":"--","model":"iPhone12,5","IDFV":"B61785A19BE8696B4DC44A733383E35E","romCapacity":"488153","isPushEnabled":"1","appInstallTimeDiff":"1696756955347","osVersion":"17.2.1","chargeStatus":"1","isSimInserted":"1","networkType":"WIFI"}'

    d = {
        "device_id": "2d356b22f39b708c",
        "seed_id": "d81de6f4-6aa3-4e5f-b8e8-6a4f98e15a76",
        "seed_time": f"{timestamp_ms}",
        "platform": "1",
        "device_fp": "38d7efe8b7f79",  # 13位
        "app_name": "bbs_cn",
        "ext_fields": ext_fields,
    }
    res = requests.post(url, json=d)
    print(res.text)


# get_fp()


def get_qrH():
    url = "https://passport-api.miyoushe.com/account/ma-cn-passport/web/createQRLogin"
    d = {"x-rpc-app_id": X_RPC_app_id, "x-rpc-device_id": X_RPC_device_id}
    res = requests.post(url, headers=d)
    print(res.text.replace("\\u0026", "&"))
    print("===")
    print(res.status_code)
