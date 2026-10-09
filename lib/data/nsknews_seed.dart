import 'package:flutter/material.dart';

import '../models.dart';

/// Packaged content from nsknews.info photo report (June 2024).
class NsknewsSeed {
  static const newsId = 'news-nsknews-2024';
  static const galleryId = 'gallery-nsknews-2024';
  static const assetDir = 'assets/images/nsknews-2024';
  static const sourceUrl =
      'https://nsknews.info/news/dom-menakhema-reportazh-iz-edinstvennoy-v-novosibirske-sinagogi';

  static String _img(String file) => '$assetDir/$file';

  static const _galleryFiles = [
    'NET_1596.jpg',
    'NET_1674.jpg',
    'NET_1756.jpg',
    'NET_1829.jpg',
    'NET_1830.jpg',
    'NET_1839.jpg',
    'NET_1861.jpg',
    'NET_1866.jpg',
    'NET_1878.jpg',
    'NET_1881.jpg',
    'NET_1887.jpg',
    'NET_1920.jpg',
    'NET_1935.jpg',
    'NET_1942.jpg',
    'NET_1946.jpg',
    'NET_1948.jpg',
    'NET_1939.jpg',
    'NET_1950.jpg',
    'NET_1951.jpg',
    'NET_1954.jpg',
    'NET_1970.jpg',
    'NET_1800.jpg',
  ];

  static List<GalleryShot> galleryShots() => [
        for (var i = 0; i < _galleryFiles.length; i++)
          GalleryShot(
            id: 'nsk-${i.toString().padLeft(3, '0')}',
            imageUrl: _img(_galleryFiles[i]),
          ),
      ];

  static GalleryPhoto galleryAlbum() => GalleryPhoto(
        id: galleryId,
        event: {
          'ru':
              'Бейт Менахем — фоторепортаж nsknews (2024)',
          'he': 'בית מנחם — דיווח צילומים nsknews (2024)',
          'en': 'Beit Menachem — nsknews photo report (2024)',
        },
        year: 2024,
        tags: const [
          'Beit Menachem',
          'Rabbi Zaklos',
          'nsknews.info',
          'Rostislav Netisov',
        ],
        color: 0xFF1E40AF,
        icon: Icons.photo_library_outlined,
        imageUrl: _img('cover_16.jpg'),
        photos: galleryShots(),
      );

  static NewsArticle newsArticle() => NewsArticle(
        id: newsId,
        title: {
          'ru':
              '«Дом Менахема»: фоторепортаж из единственной в Новосибирске синагоги',
          'he': '«בית מנחם»: דיווח צילומים מבית הכנסת היחיד בנובוסיבירסק',
          'en':
              '“Beit Menachem”: a photo report from Novosibirsk’s only synagogue',
        },
        body: {
          'ru': _bodyRu,
          'he': _bodyHe,
          'en': _bodyEn,
        },
        date: DateTime(2024, 6, 3),
        category: {
          'ru': 'Пресса',
          'he': 'תקשורת',
          'en': 'Press',
        },
        imageColor: 0xFF1E40AF,
        icon: Icons.photo_camera_outlined,
        imageUrl: _img('cover_16.jpg'),
        published: true,
      );

  static String get _bodyRu =>
      'Еврейский общинный культурный центр «Бейт Менахем» с синагогой, детским образовательным центром, библиотекой, спортзалом и рестораном открылся в августе 2013 года. Здание с куполом и звездой Давида на кровле строили на пожертвования около десяти лет — об этом «Новосибирским новостям» рассказал главный раввин города Шнеур-Залман Заклос.\n\n'
      'Центр на пересечении Щетинкина и Каменской — дом и для религиозных, и для нерелигиозных евреев. Восточный четырёхэтажный объём выполнен в виде «нераспустившегося цветка», лепестки которого — лучи звезды Давида.\n\n'
      '![ ](${_img('NET_1978.jpg')})\n\n'
      'Раввин Заклос приехал в Новосибирск в 1999 году — первый в истории города дипломированный раввин. Уже в 2000 году открылся еврейский лицей; община собиралась в арендованном помещении на Коммунистической, 14, где однажды пережили погром. После этого, в июне 1999 года, власти выделили участок под новую синагогу.\n\n'
      '![ ](${_img('NET_1824.jpg')})\n\n'
      'Сердце «Бейт Менахем» — синагога, треть всего здания. «В еврейской традиции синагогу называют „бейт кнессет“ — здесь мы молимся, учимся и общаемся», — говорит раввин. Это единственная синагога Новосибирска.\n\n'
      '![ ](${_img('NET_1610.jpg')})\n\n'
      'Перекрытия кровли выполнены в форме звезды Давида; над молельным залом — купол, напоминающий, по словам раввина, кипу. Под куполом планируют праздничный зал на 500 человек.\n\n'
      '![ ](${_img('NET_1598.jpg')})\n\n'
      '«Для меня было важно, чтобы здание выглядело современным», — рассуждает раввин. Первый архитектор настаивал на зале без окон и ушёл из проекта, когда раввин настоял на больших окнах: «Мы хотим, чтобы нас все видели, чтобы наш свет распространялся везде, и чтобы свет города заходил к нам».\n\n'
      '![ ](${_img('NET_1965.jpg')})\n\n'
      '«Окно со следами от выстрела мы решили оставить на память», — добавляет он. — «Это говорит о том, что предстоит ещё много работы, чтобы сделать жизнь добрее. Религии разные, но мы должны жить вместе в мире и согласии».\n\n'
      '![ ](${_img('NET_1626.jpg')})\n\n'
      'Арон кодеш обрамлён витражами новосибирского художника Александра Шурица — «благодарная память о нём». С 2000 года действует женский клуб под руководством раббанит Мириам Заклос. В фойе — «Дерево благодарности» с именами тех, кто помогал строить общий еврейский дом.\n\n'
      '4 сентября 2023 года на ул. Шекспира, 9а открыли новое здание лицея «Ор Авнер» и интеграционного центра «ЛЕВ».\n\n'
      '—\n'
      'Источник: Новосибирские новости ($sourceUrl). Автор: Лариса Сокольникова. Фото: Ростислав Нетисов, nsknews.info';

  static String get _bodyEn =>
      'The Beit Menachem Jewish community cultural center — with a synagogue, children\'s education center, library, gym and restaurant — opened in August 2013. The building, with its dome and Star of David on the roof, was built over about ten years from donations, Rabbi Shneur Zalman Zaklos told Novosibirsk News.\n\n'
      'At the corner of Shchetinkina and Kamenskaya streets, the center welcomes both religious and secular Jews. The eastern four-story volume is shaped like an unopened flower whose petals are rays of the Star of David.\n\n'
      '![ ](${_img('NET_1978.jpg')})\n\n'
      'Rabbi Zaklos came to Novosibirsk in 1999 — the city\'s first ordained rabbi. The Jewish lyceum opened in 2000 while the community met in rented rooms at 14 Kommunisticheskaya Street, which once survived a pogrom. In June 1999 the city allocated land for a new synagogue.\n\n'
      '![ ](${_img('NET_1824.jpg')})\n\n'
      'The heart of Beit Menachem is the synagogue — a third of the building. “In Jewish tradition a synagogue is a beit knesset — a house of assembly where we pray, study and meet,” the Rabbi says. It is Novosibirsk\'s only synagogue.\n\n'
      '![ ](${_img('NET_1610.jpg')})\n\n'
      'The roof structure forms a Star of David; above the sanctuary rises a dome that, the Rabbi says, resembles a kippah. The space beneath is planned as a 500-seat celebration hall.\n\n'
      '![ ](${_img('NET_1598.jpg')})\n\n'
      '“It was important to me that the building look modern,” he explains. The first architect insisted on a windowless hall and left when the Rabbi demanded large windows: “We want everyone to see us — our light should spread outward, and the city\'s light should reach us.”\n\n'
      '![ ](${_img('NET_1965.jpg')})\n\n'
      '“We kept a window with a bullet mark as a reminder,” he adds, “that much work remains to make life kinder. Faiths differ, yet we must live together in peace.”\n\n'
      '![ ](${_img('NET_1626.jpg')})\n\n'
      'Stained glass by Novosibirsk artist Alexander Shurits frames the aron kodesh — “a grateful memory of him.” Since 2000 Rebbetzin Miriam Zaklos has led the women\'s club. The foyer displays a Tree of Gratitude with names of those who helped build the community home.\n\n'
      'On 4 September 2023 the new Or Avner lyceum and Lev integration center opened at 9a Shekspira Street.\n\n'
      '—\n'
      'Source: Novosibirsk News ($sourceUrl). Author: Larisa Sokolnikova. Photos: Rostislav Netisov, nsknews.info';

  static String get _bodyHe =>
      'מרכז התרבות הקהילתי היהודי «בית מנחם» — עם בית כנסת, מרכז חינוך לילדים, ספרייה, אולם ספורט ומסעדה — נחנך באוגוסט 2013. את המבנה עם הכיפה ומגן דוד על הגג בנו כעשר שנים מתרומות, סיפר ל«חדשות נובוסיבירסק» הרב הראשי של העיר שניאור זלמן זקלוס.\n\n'
      'בפינת שצ׳טינקינה וקמנסקאה נפגשים דתיים וחילונים כאחד. הנפח המזרחי בן ארבע הקומות דומה ל«פרח שטרם נפתח» — עליו קרני מגן דוד.\n\n'
      '![ ](${_img('NET_1978.jpg')})\n\n'
      'הרב זקלוס הגיע לנובוסיבירסק ב־1999 — הרב המוסמך הראשון בעיר. ב־2000 נפתח הליצאון היהודי; הקהילה התכנסה בחדרים שכורים ברחוב קומוניסטיצקאיה 14, שם אירע פעם פוגרום. ביוני 1999 העירייה הקצתה מגרש לבית כנסת חדש.\n\n'
      '![ ](${_img('NET_1824.jpg')})\n\n'
      'לב «בית מנחם» הוא בית הכנסת — שליש מהמבנה. «במסורת יהודית קוראים לבית כנסת בית כנסת — כאן מתפללים, לומדים ומדברים», אומר הרב. זהו בית הכנסת היחיד בנובוסיבירסק.\n\n'
      '![ ](${_img('NET_1610.jpg')})\n\n'
      'גג בית הכנסת בצורת מגן דוד; מעל אולם התפילה כיפה שמזכירה, לדברי הרב, כיפה. מתחתיה מתוכנן אולם חגיגות ל־500 איש.\n\n'
      '![ ](${_img('NET_1598.jpg')})\n\n'
      '«חשוב לי שהבניין ייראה מודרני», מסביר. האדריכל הראשון דרש אולם בלי חלונות ועזב כשהרב התעקש על חלונות גדולים: «רוצים שכולם יראו אותנו — שהאור שלנו יצא החוצה ואור העיר ייכנס אלינו».\n\n'
      '![ ](${_img('NET_1965.jpg')})\n\n'
      '«השארנו חלון עם סימן מכדור לזכר», מוסיף, «שעוד הרבה עבודה לפנינו כדי להפוך החיים לטובים יותר. דתות שונות, אבל חייבים לחיות יחד בשלום».\n\n'
      '![ ](${_img('NET_1626.jpg')})\n\n'
      'ארון הקודש מוקף בוויטראז׳ים של האמן אלכסנדר שוריץ — «זיכרון של תודה». מאז 2000 מובילה הרבנית מרים זקלוס מועדון נשים. בלובי «עץ הכרת התודה» עם שמות מי שסייעו לבנות הבית היהודי.\n\n'
      'ב־4 בספטמבר 2023 נחנך בניין חדש לליצאון «אור אבנר» ולמרכז «לב» ברחוב שקספיר 9א.\n\n'
      '—\n'
      'מקור: חדשות נובוסיבירסק ($sourceUrl). כותבת: לריסה סוקולניקובה. צילום: רוסטיסלב נטיסוב, nsknews.info';

  static void ensure({
    required List<NewsArticle> news,
    required List<GalleryPhoto> gallery,
    required List<HistoryEvent> history,
    required SiteCopy siteCopy,
  }) {
    _ensureNews(news);
    _ensureGallery(gallery);
    _ensureHistory(history);
    _ensureAbout(siteCopy);
  }

  static void _ensureNews(List<NewsArticle> news) {
    final i = news.indexWhere((a) => a.id == newsId);
    final article = newsArticle();
    if (i < 0) {
      news.insert(1, article);
      return;
    }
    final cur = news[i];
    if (!cur.hasImage) {
      cur.imageUrl = article.imageUrl;
    }
    if (cur.body['ru']?.contains('nsknews') != true) {
      cur.title = article.title;
      cur.body = article.body;
      cur.date = article.date;
      cur.category = article.category;
      cur.imageUrl = article.imageUrl;
      cur.published = true;
    }
  }

  static void _ensureGallery(List<GalleryPhoto> gallery) {
    final shots = galleryShots();
    final i = gallery.indexWhere((a) => a.id == galleryId);
    if (i < 0) {
      gallery.insert(1, galleryAlbum());
      return;
    }
    final album = gallery[i];
    if (album.photos.length < shots.length) {
      final have = {for (final s in album.photos) s.imageUrl};
      for (final s in shots) {
        if (!have.contains(s.imageUrl)) album.photos.add(s);
      }
    }
    if (!album.hasImage) {
      album.imageUrl = _img('cover_16.jpg');
    }
  }

  static void _ensureHistory(List<HistoryEvent> history) {
    for (final e in history) {
      if (e.year == '1999') {
        _appendIfMissing(e.description, 'ru',
            ' Община собиралась на Коммунистической, 14; после погрома в июне 1999 года мэрия выделила участок под строительство.',
            'Коммунистической');
        _appendIfMissing(e.description, 'en',
            ' The community met at 14 Kommunisticheskaya St.; after a pogrom the city allocated land in June 1999.',
            'pogrom');
        _appendIfMissing(e.description, 'he',
            ' הקהילה התכנסה ברחוב קומוניסטיצקאיה 14; אחרי פוגרום, ביוני 1999, העירייה הקצתה מגרש.',
            'פוגרום');
      }
      if (e.year == '2000') {
        _appendIfMissing(e.description, 'ru',
            ' С 2000 года женский клуб возглавляет раббанит Мириам Заклос.',
            'женский клуб');
        _appendIfMissing(e.description, 'en',
            ' Rebbetzin Miriam Zaklos has led the women\'s club since 2000.',
            'women\'s club');
        _appendIfMissing(e.description, 'he',
            ' מאז 2000 מובילה הרבנית מרים זקלוס מועדון נשים.',
            'מועדון נשים');
      }
      if (e.year == '2013') {
        _appendIfMissing(e.description, 'ru',
            ' Купол над синагогой напоминает кипу; кровля выполнена в форме звезды Давида.',
            'кипу');
        _appendIfMissing(e.description, 'en',
            ' The sanctuary dome resembles a kippah; the roof forms a Star of David.',
            'kippah');
        _appendIfMissing(e.description, 'he',
            ' כיפה מעל בית הכנסת; הגג בצורת מגן דוד.',
            'כיפה');
      }
    }
    final has2023 = history.any((e) => e.year == '2023');
    if (!has2023) {
      final todayIdx = history.indexWhere((e) => e.year == 'today');
      final insertAt = todayIdx >= 0 ? todayIdx : history.length;
      history.insert(
        insertAt,
        HistoryEvent(
          id: 'hist-2023-or-avner-lev',
          year: '2023',
          title: {
            'ru': 'Ор Авнер и «ЛЕВ»',
            'en': 'Or Avner & Lev campus',
            'he': 'אור אבנר ו«לב»',
          },
          description: {
            'ru':
                '4 сентября 2023 года торжественно открыли новое здание еврейского лицея «Ор Авнер» и интеграционного центра «ЛЕВ» на ул. Шекспира, 9а.',
            'en':
                'On 4 September 2023 the new Or Avner Jewish lyceum and Lev integration center opened at 9a Shekspira Street.',
            'he':
                'ב־4 בספטמבר 2023 נחנך בניין חדש לליצאון «אור אבנר» ולמרכז השילוב «לב» ברחוב שקספיר 9א.',
          },
        ),
      );
    }
  }

  static void _ensureAbout(SiteCopy siteCopy) {
    _appendIfMissing(siteCopy.aboutBody, 'ru',
        ' Витражи вокруг арон кодеш создал художник Александр Шуриц; в фойе — «Дерево благодарности» с именами жертвователей.',
        'Шуриц');
    _appendIfMissing(siteCopy.aboutBody, 'en',
        ' Stained glass around the aron kodesh is by artist Alexander Shurits; the foyer holds a Tree of Gratitude naming donors.',
        'Shurits');
    _appendIfMissing(siteCopy.aboutBody, 'he',
        ' ויטראז׳ים סביב ארון הקודש מאת האמן אלכסנדר שוריץ; בלובי «עץ הכרת התודה» עם שמות התורמים.',
        'שוריץ');
    _appendIfMissing(siteCopy.aboutBody, 'ru',
        ' Купол синагоги напоминает кипу; кровля — звезда Давида.',
        'звезда Давида');
    _appendIfMissing(siteCopy.aboutBody, 'en',
        ' The synagogue dome evokes a kippah; the roof is shaped as a Star of David.',
        'Star of David');
    _appendIfMissing(siteCopy.aboutBody, 'he',
        ' כיפת בית הכנסת מזכירה כיפה; הגג — מגן דוד.',
        'מגן דוד');
  }

  static void _appendIfMissing(
    Loc map,
    String lang,
    String extra,
    String needle,
  ) {
    final cur = map[lang] ?? '';
    if (cur.contains(needle)) return;
    map[lang] = '$cur$extra'.trim();
  }
}
