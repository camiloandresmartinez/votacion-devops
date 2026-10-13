import unittest
from app import app


class TestVote(unittest.TestCase):

    def setUp(self):
        app.config['TESTING'] = True
        self.cliente = app.test_client()

    def test_la_pagina_responde(self):
        respuesta = self.cliente.get('/')
        self.assertEqual(respuesta.status_code, 200)

    def test_muestra_las_dos_opciones(self):
        html = self.cliente.get('/').get_data(as_text=True)
        self.assertTrue('Cats' in html, "no aparece la opción A en la página")
        self.assertTrue('Dogs' in html, "no aparece la opción B en la página")

    def test_asigna_cookie_de_votante(self):
        respuesta = self.cliente.get('/')
        self.assertIn('voter_id', respuesta.headers.get('Set-Cookie', ''))

    def test_sin_redis_no_se_cae(self):
        respuesta = self.cliente.post('/', data={'vote': 'a'})
        self.assertEqual(respuesta.status_code, 200)

    def test_healthz_devuelve_503_sin_redis(self):
        respuesta = self.cliente.get('/healthz')
        self.assertEqual(
            respuesta.status_code, 503,
            "sin Redis, /healthz debe devolver 503 para que el balanceador lo saque"
        )

    def test_healthz_informa_de_cada_dependencia(self):
        datos = self.cliente.get('/healthz').get_json()
        self.assertIn('redis', datos)
        self.assertIn('database', datos)

    def test_livez_responde_aunque_no_haya_redis(self):
        respuesta = self.cliente.get('/livez')
        self.assertEqual(
            respuesta.status_code, 200,
            "livez debe responder 200 mientras el proceso viva, incluso sin dependencias"
        )

if __name__ == '__main__':
    unittest.main()
