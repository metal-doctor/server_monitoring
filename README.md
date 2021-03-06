# server_monitoring
Набор настроенных приложений для мониторинга серверов. Выполняется сбор показателей производительности серверов, их визуализация и оповещение при достижении критических значений.
Хранение, визуализация и оповещение выполняется с помощью сервисов и их конфигурационных файлов, описанных в docker compose файле. В docker compose файле описаны сервисы:  
  - prometheus - хранение показателей,  
  - graphite-exporter - прием сообщений с показателями,  
  - alertmanager - оповещение,  
  - grafana - визуализация,  
  - nginx - реверс прокси для безопасности.

Сбор и отправка показателей производительности сервера выполняется с помощью приложения telegraf. Запуск telegraf может выполняться в виде приложения или в виде службы.

## Описание используемых компонент
Для сбора и хранения показателей используется приложение [prometheus](https://prometheus.io/). Prometheus использует модель pull (тянуть, "дергать") запросов для получения показателей. Такой подход удобен, если prometheus и наблюдаемый сервер находятся "рядом", но при необходимости сбора показателей на "удаленных" серверах гораздо удобнее и безопаснее использовать модель push (толкать) запросов.  
Поэтому, используется официальное расширение (exporter) [graphite-exporter](https://github.com/prometheus/graphite_exporter). Расширение запускается как отдельное приложение: оно принимает push сообщения с показателями, преобразует их и предоставляет для использования prometheus с помощью pull модели запросов.  
Для отправки push сообщений используется приложение [telegraf](https://github.com/influxdata/telegraf). У telegraf есть много различных плагинов для получения показателей ОС, СУБД и различных приложений. В данном случае используется плагин win_perf_counters для сбора показателей ОС windows. Собираются основные показатели производительности ЦП, оперативной памяти, дисков и сетевых интерфейсов. По умолчанию показатели отправляются раз в минуту.  
Для визуализации показателей используется grafana с предустановленными дашбоардами: overview, disk_overview, memory_overview.  
Для отправки предупреждений о критических ситуациях используется alertmanager. Предустановлена отправка электронных сообщений при превышении загруженности ЦП более 50% в течении 5 минут, при уменьшении доступной оперативной памяти менее 2 Гб, при уменьшении свободного дискового пространства менее 10%.  
Для безопасного подключения к grafana и передачи показателей graphite-exporter используется реверс прокси nginx. Используется самоподписанный сертификат.


## Быстрый старт для мониторинга в локальной сети
Предполагается, что уже есть linux сервер и на нем установлены последние версии docker и docker-compose.
1. Скопировать файл install.sh и архив prometheus_server.tar.
2. Разрешить исполнение скрипта install.sh: `chmod +x install.sh`
3. Запустить скрипт install.sh.
4. Перейти в каталог prometheus_server.
5. Запустить команду:  
  `docker-compose up`  
Будут загружены последние образы используемых приложений и запущены в отдельных контейнерах.  
В консоли будут выводиться сообщения от приложений. Для запуска приложений в фоне нужно выполнить команду:  
  `docker-compose up -d`
6. Изменить адрес отправки показателей в файле telegraf.conf в разделе outputs.graphite с your-server:9109 на локальный адрес linux сервера.
Запустить отправку показателей с помощью telegraf:  
  `telegraf.exe --config telegraf.conf`  
Просмотр показателей доступен в grafana по адресу your-server:3000. По умолчанию для первой авторизации используются логин, пароль: admin, admin.

## Настройка оповещений по электронной почте
В файле alertmanager/alertmanager.yml:  
  - заполнить настройки отправки сообщений по электронной почте smtp_*,  
  - указать получателей в разделе receivers в параметре email_configs - to.

## Настройка для мониторинга серверов вне локальной сети
Для приема сообщений с показателями от серверов вне локальной сети используется реверс прокси nginx с SSL/TLS. Для этого нужно в docker compose файле раскомментировать сервис nginx и в конфигурационном файле nginx/nginx.conf раскомментировать секцию stream. Запустить контейнер с сервисом nginx:  
  `docker-compose up -d nginx`  
В конфигурационном файле telegraf/telegraf.conf в разделе outputs.graphite раскомментировать настройку insecure_skip_verify = true.
После этого можно отправлять сообщения с показателями производительности на внешний адрес по порту 49109.

## Настройка для просмотра показателей вне локальной сети
Для просмотра показателей не из локальной сети нужно в docker compose файле для сервиса grafana раскомментировать раздел environment и заменить your-server на внешний адрес, а также раскомментировать в конфигурационном файле nginx/nginx.conf секцию http и заменить в ней параметр server_name c your-server.com на внешний адрес. Создать заново контейнер с grafana:  
  `docker-compose up -d grafana`  
Перезапустить сервис nginx:  
  `docker-compose restart nginx`  
Не из локальной сети к grafana можно подключиться по адресу https://your-server.com/grafana.
Из локальной сети к grafana можно подключиться по адресу https://your-server/grafana.

При использовании релизов с включенным реверс прокси (с суффиксом with_reverse_proxy) для начала использования достаточно настроить:  
  - В конфигурационном файле telegraf/telegraf.conf в разделе outputs.graphite раскомментировать настройку insecure_skip_verify = true.
После этого можно отправлять сообщения с показателями производительности на внешний адрес по порту 49109.
  - В docker compose файле для сервиса grafana в разделе environment заменить your-server на внешний адрес и в конфигурационном файле nginx/nginx.conf в секции http заменить параметр server_name c your-server.com на внешний адрес.

## Описание результата
Запущены сервисы:
  - prometheus:9090 - выполнение и отладка запросов к prometheus,
  - graphite-exporter:9108 - просмотр принимаемых показателей,
  - graphite-exporter:9109 - прием сообщений с показателями,
  - alertmanager:9093 - просмотр оповещений,
  - grafana:3000 - просмотр показателей,
  - nginx:443 - просмотр показателей через реверс прокси,
  - nginx:49109 - прием сообщений с показателями через реверс прокси.

Для подключения к запущенным приложениям с linux сервера нужно использовать localhost, например, localhost:9090. Для подключения к запущенным приложениям из локальной сети нужно использовать имя linux сервера, например, your-server:9090.

Для просмотра списка и статуса всех контейнеров  нужно выполнить команду:  
  `docker-compose ps`  
Для остановки приложений нужно выполнить команду:  
  `docker-compose stop`  
Для удаления созданных контейнеров нужно выполнить команду:  
  `docker-compose down`  

## Описание настроек сервисов в docker compose файле.
Сервис prometheus  
  - prometheus/prometheus.yml - настройки хранения данных, сбора показателей из graphite-exporter, правил генерации оповещений rules.yml, отправки оповещений в alertmanager
  - prometheus/rules.yml - правила генерации оповещений
  - prometheus/data - каталог хранения данных

Сервис graphite-exporter
  - graphite-exporter/graphite-exporter.yml - настройки преобразования сообщений с показателями производительности из формата graphite в формат prometheus

Сервис alertmanager
  - alertmanager/alertmanager.yml - настройки обработки и методов доставки оповещений
  - alertmanager/data - хранение данных оповещений

Сервис grafana
  - GF_SERVER_DOMAIN=your-server.com
  - GF_SERVER_ROOT_URL=%(protocol)s://%(domain)s/grafana
  переменные окружения устанавливаются для использования grafana через реверс прокси nginx
  - grafana/grafana-storage - хранение данных grafana: источники, дашбоарды

Сервис nginx
  - nginx/nginx.conf - настройки прокси сервера
  - nginx/cert - самоподписанные сертификаты для использования защищенного соединения

## Отладка
prometheus
  - your-server:9090 - выполнение и отладка запросов к prometheus

graphite-exporter
  - your-server:9108 - просмотр принимаемых показателей

alertmanager
  - your-server:9090/alerts - просмотр правил оповещений и их генерации
  - your-server:9093 - просмотр обработки оповещений

telegraf
  - telegraf.exe --config telegraf_debug.conf - отладка получения, отправки показателей  
  Получение и вывод одного показателя в консоль. Дополнительную информацию можно посмотреть в лог файле telegraf.log.

Просмотр журналов приложений:  
  `docker-compose logs prometheus`

Подключение к контейнеру с приложением:  
  `docker-compose exec prometheus bash`  
  или  
  `docker-compose exec prometheus sh`
