# Get Pizzas!

### Usage

Create a `.env` file in the root and fill it like this

```
TELEGRAM_BOT_TOKEN=ASK_BOTFATHER_FOR_YOURS
DATABASE_NAME=db/your_db_name
DATABASE_ADAPTER=your_db_adapter
```

Then use [Foreman](https://github.com/ddollar/foreman) to launch it.

```
foreman start
```

### Deployment

Currently the bot is deployed on `dev`.

Deploy:

```
$ scp -r * ict4g@dev.ict4g.org:/home/ict4g/orostube-bot
```

then on `dev` restart the process

```
$ cd orostube-bot
$ screen -r
Ctrl+C
$ screen -S orostube-bot foreman start
```

Done!

### TODO

* Calculate price per person for an order
* Start a new order and send link to others
* Make money and __fatturare__

### Credits

This bot is largely inspired by the [Ruby Telegram Bot boilerplate](https://github.com/MaximAbramchuck/ruby-telegram-bot-boilerplate)
