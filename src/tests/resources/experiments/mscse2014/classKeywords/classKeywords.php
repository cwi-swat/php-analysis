<?php

namespace ns;

class p {}

class c extends p {
    public function se() { self::foo(); }
    public function pa() { parent::foo(); }
    public function st() { static::foo(); }
}
