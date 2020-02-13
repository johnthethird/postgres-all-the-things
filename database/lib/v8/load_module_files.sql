\! pwd
\! ./load_module_from_url.sh babel-polyfill https://unpkg.com/babel-polyfill/dist/polyfill.js
\! ./load_module_from_url.sh react https://unpkg.com/react/umd/react.production.min.js
\! ./load_module_from_url.sh react-dom-server https://unpkg.com/react-dom/umd/react-dom-server.browser.production.min.js
\! ./load_module_from_url.sh immutable https://unpkg.com/immutable/dist/immutable.js
\! ./load_module_from_url.sh slate https://unpkg.com/slate/dist/slate.js
\! ./load_module_from_url.sh slate-plain-serializer https://unpkg.com/slate-plain-serializer/dist/slate-plain-serializer.min.js
\! ./load_module_from_url.sh slate-html-serializer https://unpkg.com/slate-html-serializer/dist/slate-html-serializer.min.js

\! ./load_module_from_url.sh lodash https://cdnjs.cloudflare.com/ajax/libs/lodash.js/4.17.5/lodash.min.js

\! ./load_module_from_url.sh faker https://cdnjs.cloudflare.com/ajax/libs/Faker/3.1.0/faker.min.js

UPDATE v8.modules SET autoload = true WHERE module = 'babel-polyfill';
