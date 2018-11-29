### Ares
---
Ares (/ ˈ ɛər iː z /; Ancient Greek: Ἄρης, Áres) is the Greek god of war.

Um software em Ruby e ChromeDriver que lê e organiza metadados de grupos do Whatsapp para posterior análises.

---


#### install on linux debian
```
# install ruby
sudo apt-get install ruby ruby-dev ruby-bundler chromium-chromedriver;
# install required libraries
bundle install;
```

#### run
```
# lê hashes.json com invite de grupos e gera metadados em meta_hashes.json
./ares.rb meta

# lê históricos em data/history e cria .json estruturando mensagens em {who, when, what}
./ares.rb history
```
