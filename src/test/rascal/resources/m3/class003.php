<?php 

namespace A;

class C {
    const c = "c";
    public $pub;
    private $priv;
    protected $pro;

	public function pubFunc($param1, $param2) {}
    private function privFunc($param1, $param2) {}
    protected function proFunc($param1, $param2) {}
}

namespace A\B;

final class C {
    const c = "c";
    public $pub;
    private $priv;
    protected $pro;

    final public function pubFunc($param1, $param2) {}
    final private function privFunc($param1, $param2) {}
    final protected function proFunc($param1, $param2) {}
}
