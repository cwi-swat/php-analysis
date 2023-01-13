<?php

namespace ns;

class p {}

class se extends p { public function se() { self::foo(); } }
class pa extends p { public function pa() { parent::foo(); } }
class st extends p { public function st() { static::foo(); } }
class th extends p { public function th() { $this::foo(); } }
