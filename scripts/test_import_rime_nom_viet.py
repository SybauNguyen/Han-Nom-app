#!/usr/bin/env python3
import unittest
from import_rime_nom_viet import decode_telex_code, parse_rime_lines


class RimeNomVietImporterTests(unittest.TestCase):
    def test_common_telex_examples(self):
        self.assertEqual(decode_telex_code('nguowfi'), 'người')
        self.assertEqual(decode_telex_code('vieetj'), 'việt')
        self.assertEqual(decode_telex_code('tooi'), 'tôi')
        self.assertEqual(decode_telex_code('awn'), 'ăn')
        self.assertEqual(decode_telex_code('cowm'), 'cơm')
        self.assertEqual(decode_telex_code('gais'), 'gái')

    def test_parse_unique_single_characters_and_skip_curriculum(self):
        lines = [
            '---', 'name: nom_viet', 'version: "test"', '...',
            '𠊛\tnguowfi\t100',
            '𠊛\tnguoi\t90',  # duplicate output should be skipped
            '𡚥\tgais\t80',
            '越南\tvieetj nam\t70',  # compound should not be imported
            '一\tyi\t60',  # supplied curriculum symbol should be skipped
            '# a comment',
        ]
        records, skipped = parse_rime_lines(lines, limit=10, blocked_characters={'一'})
        self.assertEqual([r['character'] for r in records], ['𠊛', '𡚥'])
        self.assertEqual(records[0]['han_viet_reading'], 'người')
        self.assertEqual(records[1]['han_viet_reading'], 'gái')
        self.assertTrue(all(r['type'] == 'Nôm' for r in records))
        self.assertGreaterEqual(skipped, 3)

    def test_accept_reversed_columns(self):
        records, _ = parse_rime_lines(['---', 'name: x', '...', 'nguowfi\t𠊛\t10'], limit=2, blocked_characters=set())
        self.assertEqual(records[0]['character'], '𠊛')
        self.assertEqual(records[0]['han_viet_reading'], 'người')


if __name__ == '__main__':
    unittest.main()
