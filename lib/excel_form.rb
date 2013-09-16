#coding:utf-8
require 'excel_form/version'

module ExcelForm
  class Ef
    attr_accessor :digit, :sum_arr

    def initialize
      @digit = 2
      @sum_arr = []
      @header = ''

    end

    def defaults_options

    end

    def decimal_digit(digit)
      result =<<-DDJS
        function cc(s) {
        if (/[^0-9\.]/.test(s)) return "";
        s = s.replace(/^(\d*)$/, "$1.");
        s = (s + "#{'0'*digit}").replace(/(\d*\.#{'\d'*digit})\d*/, "$1");
        s = s.replace(".", ",");
        var re = /(\d)(\d{3},)/;
        while (re.test(s))
            s = s.replace(re, "$1,$2");
        s = s.replace(/,(#{'\d'*digit})$/, ".$1");
        return s.replace(/^\./, "0.")
        }
      DDJS
    end

    def sum_validate(arr)
      result =<<-SVJS
    function FieldValidator(value) {
        if (isNaN(value)) {
            return {valid: false, msg: "只能输入数字！"};
        } else {
            if (data[1][1] != (parseFloat(data[2][1]) + parseFloat(data[3][1]))) {
                return {valid: true, msg: "营业收入应该为主营业务收入和其他业务收入之和！"};
            }

            return {valid: true, msg: null};
        }
    }
      SVJS
    end

    def generate_header(headers)
      result = ''
      headers.each do |h|
        i = headers.index(h)
        result << "columns.push({id: #{i},name: #{h},field: #{i},width: 100,editor: FormulaEditor,sortable: false,asyncPostRender: formatThousandChar,validator: FieldValidator});"
      end
      result
    end

    def auto_complete

    end


    def generate_form(digit, sum_arr, headers)
      result =<<JSCRIPT
        //转换千分符
    #{decimal_digit(digit)}
    //验证
    #{sum_validate(sum_arr)}

    //grid
    var grid;
    var data = [];
    var options = {
        editable: true,
        enableAddRow: false,
        //鼠标可以点击格
        enableCellNavigation: true,
        enableAsyncPostRender: true,//
        autoHeight: true,//
        autoEdit: false,
        cellHighlightCssClass: "highlight",
        cellFlashingCssClass: "flashing",
        defaultFormatter: function (row, cell, value, columnDef, dataContext) {
            if (value == null)
                return '';
            //页面上又进行了一次编码，所以&nbsp传过来是&amp;nbsp;，要进行解码
            return $('<div/>').html(value).text();
        }
    };
    //标题
    var columns = [];
    #{generate_header(headers)}

    function FormulaEditor(args) {
        var _self = this;
        var _editor = new Slick.Editors.Text(args);
        var _selector;

        $.extend(this, _editor);

        function init() {
            // register a plugin to select a range and append it to the textbox
            // since events are fired in reverse order (most recently added are executed first),
            // this will override other plugins like moverows or selection model and will
            // not require the grid to not be in the edit mode
            _selector = new Slick.CellRangeSelector();
            _selector.onCellRangeSelected.subscribe(_self.handleCellRangeSelected);
            args.grid.registerPlugin(_selector);
        }

        this.destroy = function () {
            _selector.onCellRangeSelected.unsubscribe(_self.handleCellRangeSelected);
            grid.unregisterPlugin(_selector);
            _editor.destroy();
        };

        this.handleCellRangeSelected = function (e, args) {
            _editor.setValue(
                    _editor.getValue() +
                            grid.getColumns()[args.range.fromCell].name +
                            args.range.fromRow +
                            ":" +
                            grid.getColumns()[args.range.toCell].name +
                            args.range.toRow
            );
        };


        init();
    }

    function formatThousandChar() {
        //自动填充
        #{auto_complete}
        var val1 = data[1][columns[1].field] || '0';
        var val2 = data[2][columns[1].field] || '0';
        var val3 = data[3][columns[1].field] || '0';
        var val4 = data[4][columns[1].field] || '0';
        var val5 = data[5][columns[1].field] || '0';
        var val6 = data[6][columns[1].field] || '0';
        var val = parseFloat(val1) + parseFloat(val2) + parseFloat(val3) + parseFloat(val4) + parseFloat(val5) + parseFloat(val6);
        //innerHTML只能改变页面显示，不能改变data实际的值
        grid.getCellNode(0, 1).innerHTML = val;

        //调用转换千分符
        for (var i = 0; i < 100; i++) {
            for (var k in [1, 2, 4, 5]) {
                var j = [1, 2, 4, 5][k];
                if (grid.getCellNode(i, j) != null) {
                    var val = grid.getCellNode(i, j).innerHTML;
                    if (!isNaN(val) && val != 0) {
                        grid.getCellNode(i, j).innerHTML = cc(val);
                    }
                }
            }
        }
        //输入错误高亮闪烁
        if (data[1][1] != (parseFloat(data[2][1]) + parseFloat(data[3][1]))) {
            $('#error').html('营业收入应该为主营业务收入和其他业务收入之和！');
            $('#error').addClass('alert alert-error');
            grid.setCellCssStyles("yingyeshouru", {
                1: {
                    1: "highlight"
                },

                2: {
                    1: "highlight"
                },

                3: {
                    1: "highlight"
                }
            })
        }
        else {
            $('#error').html(' ');
            $('#error').removeClass('alert alert-error');
            grid.removeCellCssStyles("yingyeshouru")
        }


    }

    $(function () {
        var str = '<%= @struct_data %>';
        var arr = str.split('@');
        for (var i = 0; i < arr.length; i++) {
            var a = arr[i].split(',');
            var d = (data[i] = {});
            for (var j = 0; j < a.length; j++) {
                d[j] = a[j];
            }

        }

        grid = new Slick.Grid("#myGrid", data, columns, options);

        grid.onCellChange.subscribe(function (e, args) {
            if (data[1][1] != (parseFloat(data[2][1]) + parseFloat(data[3][1]))) {
                grid.scrollRowIntoView(1, false);
                grid.flashCell(1, 1, 200);
            }
            //
            var activeCellNode = args.cellNode;
            $(activeCellNode).attr("title", '');
        });

        grid.setSelectionModel(new Slick.CellSelectionModel());
        grid.registerPlugin(new Slick.AutoTooltips());

        // set keyboard focus on the grid
        grid.getCanvasNode().focus();

        var copyManager = new Slick.CellCopyManager();
        grid.registerPlugin(copyManager);
        //excel式的复制粘贴
        copyManager.onPasteCells.subscribe(function (e, args) {
            if (args.from.length !== 1 || args.to.length !== 1) {
                throw "This implementation only supports single range copy and paste operations";
            }

            var from = args.from[0];
            var to = args.to[0];
            var val;
            for (var i = 0; i <= from.toRow - from.fromRow; i++) {
                for (var j = 0; j <= from.toCell - from.fromCell; j++) {
                    if (i <= to.toRow - to.fromRow && j <= to.toCell - to.fromCell) {
                        val = data[from.fromRow + i][columns[from.fromCell + j].field];
                        if (!isNaN(val)) {
                            data[to.fromRow + i][columns[to.fromCell + j].field] = val;
                            grid.invalidateRow(to.fromRow + i);
                        }
                    }


                }
            }
            grid.render();
        });

        var handleValidationError = function (e, args) {
            var validationResult = args.validationResults;
            var activeCellNode = args.cellNode;
            var errorMessage = validationResult.msg
            var valid_result = validationResult.valid;
            if (!valid_result) {
                $(activeCellNode).attr("title", errorMessage);
            }
            else {
                //修改源码，让验证为true时也能执行这个方法
                $(activeCellNode).attr("title", "");
            }
            poshytip(activeCellNode);


        }

        function poshytip(obj) {
            $(obj).poshytip({showTimeout: 1});
        }

        var destroyTip = function (e, args) {
            var editor = args.editor;
            alert(editor.attr('das'));
            $(editor).attr("title","");
        }

        grid.onValidationError.subscribe(handleValidationError);

    })
    function hasClass(ele,cls) {
        return ele.className.match(new RegExp('(\\s|^)'+cls+'(\\s|$)'));
    }
    //数据有误，不能提交
    function submitFun() {
        var check = true;
        var data_str = '';
        for (var i = 0; i < data.length; i++) {
            for (var j = 0; j < 6; j++) {
                //判断是否有元素高亮
                if(hasClass(grid.getCellNode(i, j), "highlight")) {
                    check = false;
                }
                //拼成数据
                data_str += data[i][j];
                if (j != 5) {
                    data_str += ','
                }
            }
            data_str += '@';
        }
        if (check) {
            $("#new_data").val(data_str);
            $('form').submit();
        }
        else {
            alert('请确认数据的正确性！');
        }

    }

JSCRIPT
    end

  end

end
