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
        self.assertIn('Cats', html)
        self.assertIn('Dogs', html)

    def test_asigna_cookie_de_votante(self):
        respuesta = self.cliente.get('/')
        self.assertIn('voter_id', respuesta.headers.get('Set-Cookie', ''))

    def test_sin_redis_no_se_cae(self):
        respuesta = self.cliente.post('/', data={'vote': 'a'})
        self.assertEqual(respuesta.status_code, 200)


if __name__ == '__main__':
    unittest.main()
