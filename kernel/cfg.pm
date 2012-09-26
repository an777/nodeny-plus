# Если параметр run = 1, то модуль запускается автоматически.
# В противном случае модуль запускается только при конкретном его указании,
# например:
#   perl nokernel.pl -v -m=turbosms
# Есть смысл запускать модуль отдельно, когда в нем могут быть блокирующие
# или медленные операции, которые приводят к несвоевременному выполнению
# подпрограмм других модулей.
#
# Параметр period - период запуска модуля

$cfg::plugins = {

    demo => {
        run => 0,
        period => 4*60*60,
    },

# Проверка системы. Ошибки пишутся в таблицу платежей/событий pay

    system_check => {
        run => 1,
        period => 4*60*60,
    },

# Чистка системы:

    system_clean => {
        run => 1,
        period      => 24*60*60,
            # количество дней хранения данных трафика
        traf_X_day    => 60,
            # количество дней хранения данных детализации трафика
        traf_Z_day    => 30,
    },

# Удаляет web-сессии по таймауту. period - это не длительность сессии, а период
# проверки стоил ли удалять устаревшие сессии

    websession => {
        run => 1,
        period => 5*60,
    },

# Сервер nodeny-авторизации (программой авторизатором)

    authserver => {
        run => 1,
        bind_port   => 7723,
            # ip либо 0 - сервер биндится на все ip системы
        bind_ip     => 0,
            # Данные о конкретном клиенте разрешено получать не чаще чем раз в load_user_min_period
            # Запросы на авторизацию клиенты посылают с периодом несколько десятков секунд, поэтому период
            # нет смысла делать очень маленьким
        load_user_min_period => 25,
    },


# Удаляет авторизации по таймауту и пишет историю логинов в таблицу auth_log.
#   timeout - время в секундах, по прошествии которого, клиент будет считаться
#           неавторизованным для доступа в интернет. Если не запустить данный
#           модуль, клиент будет авторизован всегда с момента первой авторизации

    auth => {
        run => 1,
        period => 5,
        timeout => 150,
    },

# Удаляет услуги, время которых завершилось. Если автопродление - подключает новую

    services => {
        run => 1,
    },

# Проверяет балансы клиентов и блокирует учетку, если ниже границы отключения

    balance => {
        run => 1,
        period => 7,
    },

# Плагин временных платежей. Удаляет просроченные временные платежи
    tmppays => {
        run => 1,
    },

# Завершение услуг, трафик которых исчерпан

    chk_traf => {
        run => 0,
    },


# Сбор статистики трафика

    collectors => {
        run    => 1,
        period => 60,
        list   => [
            {
                type => 'ipcad',
                addr => '127.0.0.1',
                rsh => '/usr/bin/rsh',
            },
#            {
#                type => 'ipcad',
#                addr => '127.0.0.2',
#                rsh => '/usr/bin/rsh',
#            },
        ],
    },
    
    lost_ping => {
        run => 0,
        ping_cmd    => '/sbin/ping -fqn -c 1000',
        regexp      => '(\d+\.\d+)% packet loss',
        data_field  => 'lost_ping',
        period      => 5*60,
    },

# Отправляет клиенту через http://turbosms.ua sms о том, что в ближайшее время
# будет произведено списание за услуги и его счет может быть заблокирован,
# если он его не пополнит. Условия отсылки:
#   стоимость подключаемой в будущем услуги > 0 (т.е не бонус, а снятие),
#   текущий баланс меньше стоимости следующей услуги,
#   включена блокировка при балансе ниже лимита,
#   в данный момент доступ включен,
#   не подключена бонусная услуга, которая могла бы увеличить баланс

    turbosms => {
        run => 0,

        sms         => '{{date}} списание за услуги интернет. Пополните счет.',

        # Извлечение телефона из текстовой строки, которая может содержать несколько телефонов, не цифры и т.д.
        phone_extract => sub{
            my($phone) = @_;
            $phone =~ s/^\s*//;
            $phone =~ s/^\+//;
            $phone =~ s/[^\d\-].*$//;
            $phone =~ s/\D//g;
            $phone =~ s/^3?8//g;
            length($phone) == 10 or return '';
            $phone =~ /^0/ or return '';
            return '+38'.$phone;
        },
    },

    make_config => {
        run => 0,
        period => 60,
        config => [
            'dhcp.tmpl',
        ]
    },

    dhcp_server => {
    },
    
# Модуль заглушки. Если клиент не авторизован/заблокирован/неверные сетевые настройки,
# все http запросы редиректятся на внутренний web-сервер, который является модулем ядра NoDeny.
# На все эти запросы модуль будет отвечать редиректом на страницу https://ваш.домен/cgi-bin/cap.pl

    cap => {
        run => 0,
        port     => 8080,
        url      => 'http://inet.l3.dp.ua/cgi-bin/cap.pl',
        redirect => "<!doctype html>
<html>
<head>
    <meta http-equiv='Cache-Control' content='no-cache'>
    <meta http-equiv='Pragma' content='no-cache'>
    <meta http-equiv='refresh' content='0; url={{url}}'>
</head>
<body><a href='{{url}}'>Click</a></body>
</html>",
    },
};
