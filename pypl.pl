#!/usr/bin/perl -w

# Starting point for COMP[29]041 assignment 1
# http://www.cse.unsw.edu.au/~cs2041/assignments/pypl
# written by z5108573@unsw.edu.au September 2017

sub parse_statement {
    my ($index) = @_;
    
    #translate the print statement
    if($python[0] =~ /^\s*import(.*)$/) {
        my $python = shift @python;
        return "";    
    }
    #translate the commentline
    elsif($python[0] =~ /^\s*\#(.*)$/){
        my $tempComment = $python[0];
        my $python = shift @python;
        return $tempComment;
    }
    #handle standard output
    elsif($python[0] =~ /^\s*sys\.stdout\b/) {
        return parse_stdIO($index);    
    }
    #translate the print function
    elsif($python[0] =~ /^\s*print\b/) {
        return parse_print($index);   
    }
    #translate the if statement
    elsif($python[0] =~ /^\s*if\b/) {
        return parse_if($index);
    }
    #translate the while loop
    elsif($python[0] =~ /\bwhile\b/i) {
        return parse_while($index);
    }
    #tranlate the for loop
    elsif ($python[0] =~ /^\s*for\b/) {
        return parse_forloop($index);
    }
    #translate the break/continue/-=/+=/*=//=
    elsif($python[0] =~ /(^\s*break\s*$|^\s*continue\s*$|^\s*\w+\s*\-\=|^\s*\w+\s*\+\=|^\s*\w+\s*\*\=|^\s*\w+\s*\/\=)/) {
        return parse_util($index);
    }
    #translate the variable to add scalar
    elsif($python[0] =~ /^\s*[A-Za-z0-9]+\[?(.*)\]?\s*(\+)?\=.*\s*$/) {
        return parse_scalar($index);
    }
    #handle append
    elsif($python[0] =~ /^\s*[A-Za-z0-9]+\.append(.*)$/){
        return parse_append($index);
    }
    #other special cases
    elsif($python[0] =~ /.*(\+\=).*/) {
        return parse_scalar($index)
    }
    #for empty line
    else{
        my $python = shift @python;
        return $python;
    }

}
#funtion to handle append
sub parse_append {
    my ($index, $python) = @_;
    $python = shift @python if !$python;
    my $list ='';
    my @content=();
    my $result ='';
    if($python =~ /^\s*(.*)\.append(.*)$/){
        my $first = $1;
        my $second = $2;
        $second =~ s/(\(|\))//g; 
        if($second =~ /^[0-9]+$/){
            $second = $second;
        }else{
            $second = '$'.$second;
        }
        $result = " "x($index).'push '.'@'.$first.', '.$second.";\n";
    }
    return $result;
}

#for loop function
sub parse_forloop {
    my ($index) = @_;
    my $python = shift @python;
    my @for_perl = ();
    my $wordE = ();
    my $operE = ();
    if($python =~ /^\s*for\s*(\w+)\s*in\s*(\w+)\((.*)\)\s*\:$/) {
        my $i = $1;
        my $type =$2;
        my $range = $3;
        my $output = '';
        if($type =~ /range/){
            if($range =~ /^(.*)\,\s*(.*)$/) {
                my $start = $1;
                my $end = $2;
                if($start =~ /^[0-9]+$/){
                    $start = $start;
                }else{
                    $start = "\$".$start;
                }
                if($end =~ /^\s*[0-9]+$/){
                    $end = ($end - 1);
                }else{
                    
                    if($end =~ /^\s*len\((.*)\)\s*$/){
                        $sysLenflag = 1;
                        if($1 =~ /^\s*sys\.argv\s*$/){
                            $end = '@ARGV';
                        }else{
                            $end = '@'.$1;
                        }
                        
                    }else {
                        for my $y (split /\s?\W\s?/, $end) {
                            if($y =~ /^[^A-Za-z]+$/){
                                push @wordE, $y;
                            }
                            else{
                                push @wordE, "\$".$y;
                            }
                        
                        }
                        for my $z (split /\w/,$end){
                            if($z =~ /\*|\-|\+|\/|\%/){
                                push @operE,$z; 
                            }
                        }
                        my $i = 0;
                        my $size = @operE;
                        $end = '';
                        while($i < $size){
                            $end .=$wordE[$i]." ".$operE[$i]." "; 
                            $i++;
                        }
                        # print "herererer     $wordE[$size]\n";
                        if($wordE[$size] =~ /\$/) {
                            $end .=$wordE[$size].'- 1';
                        }else{
                            if($operE[$size-1] =~ /\+/){
                                
                                if($wordE[$size] =~ /^[1]$/){
                                    $wordE[$size] =~ s/1/0/g;
                                    $end .=$wordE[$size];
                                    $end =~ s/(\s*\+\s*0$)//g;
                                }else{
                                    
                                    $end .=$wordE[$size]-1;
                                }
                            }elsif($operE[$size - 1] =~ /\-/){
                                
                                if($wordE[$size] =~ /^0$/){
                                    $wordE[$size] =~ s/0/1/g;
                                    $end .=$wordE[$size];
                                }else{
                                    $end .=$wordE[$size]+1;
                                }
                            }   
                        }
                    }                    
                }                
                $output = "($start..$end)";
            }elsif($range =~ /^\s*(.*)\s*$/){
                my $checkR = $1;
                if($checkR =~ /^\s*[0-9]+\s*$/){
                    $output = "(0..$checkR-1)";
                }else{
                    $output = "(\$$checkR - 1)";
                }
            }
        }
        push @for_perl," " x($index)."foreach"." \$$i"." "."$output {\n";
    } elsif($python =~ /^\s*for\s*(\w+)\s*in\s*(.*)\s*\:$/) {
        my $i = $1;
        my $type =$2;
        my $output = '';
        if($type =~ /^\s*sys\.stdin\s*/){
            $output = '(<STDIN>)';
            push @for_perl," " x($index)."foreach"." \$$i"." "."$output {\n";
        }elsif($type =~ /^\s*sys\.argv\s*/){
            $output = '(@ARGV)';
            push @for_perl," " x($index)."foreach"." \$$i"." "."$output {\n";
        }elsif($type =~ /^\s*fileinput\.input\s*/){
            $output = 'while ($line = <>) {'."\n";
            push @for_perl," " x($index).$output;
        }     
    }
    $python[0] =~ /^(\s*)/;
    my $len = length($1);
    #recursive to add the }
    while(@python){
        $python[0] =~ /^(\s*)/;
        my $len1 = length($1);
        if($len != $len1){
            last;
        }else{
            push @for_perl, parse_statement($index + 4);
        }
    }
    push @for_perl," " x ($index)."}\n";
    push @for_perl,"";
    return @for_perl;
}

#standard output
sub parse_stdIO {
    my ($index) = @_;
    my $python = shift @python;
    my @std_perl = ();
    push @std_perl, " "x($index);
    if($python =~ /sys\.stdout/){
        $python =~ s/^\s+//g;
        $python =~ s/sys\.stdout\.write\(/print /g;
        $python =~ s/\)/\;/g;
        push @std_perl, "$python";
    }
    return @std_perl;
}

sub parse_util {
    my ($index) = @_;
    my $python = shift @python if !$python;
    chomp $python;
    if($python =~ /^\s*break\b\s*$/) {
        return  " "x($index)."last;\n";
    }
    if($python =~ /^\s*continue\b\s*$/) {
        return  " "x($index)."next;\n";
    }
    if($python =~ /^\s*([\S]+\s*\[?\d?\]?)[\+]?\s*\=\s*(.*)\s*$/){
        my $operS = $2;
        return " "x($index)."\$$1 = \$$1 + "."$2".";\n";
    }
    if($python =~ /^\s*([\S]+\s*\[?\d?\]?)[\-]?\s*\=\s*(.*)\s*$/) {
        my $operS = $2;
        return " "x($index)."\$$1 = \$$1 - "."$2".";\n";
    }
    if($python =~ /^\s*([\S]+\s*\[?\d?\]?)[\*]?\s*\=\s*(.*)\s*$/) {
        my $operS = $2;
        return " "x($index)."\$$1 = \$$1 * "."$2".";\n";
    }
    if($python =~ /^\s*([\S]+\s*\[?\d?\]?)[\/]?\s*\=\s*(.*)\s*$/) {
        my $operS = $2;
        return " "x($index)."\$$1 = \$$1 / "."$2".";\n";
    }

}

sub parse_print {
    my ($index) =@_;
    my $python = shift @python;
    my @print_perl = ();
    $python =~ s/^\s*print\b//;
    if($python =~ /^\s*\(\"(.*)\"\s*\%(.*)$/){
        # print "corrext    $python  \n";
        push @print_perl, " "x($index)."printf";
        push @print_perl, parse_printF($python);
    }else{
        push @print_perl, " "x($index)."print";
        push @print_perl, parse_rest($python);
    }
    return @print_perl;

}

sub parse_printF {
    my ($contentF) = @_;
    my $result = '';
    $contentF =~ s/\)$/\;/g;
    $contentF =~ s/^\s*\(//g;
    my @linePerc = split('\%\s',$contentF);
    $linePerc[0] =~ s/\"\s*$/\\n\"/g;
    if($linePerc[1] =~ /\,/){
        $linePerc[1] =~ s/\)//g;
        $linePerc[1] =~ s/^\s*\(//g;
        my @lineP = split('\,',$linePerc[1]);
        my $i = 0;
        my $size = @lineP;
        $result .="$linePerc[0]";
        while($i < $size) {
            if($lineP[$i] =~ /^[0-9]+$/){
                $lineP[$i] = $lineP[$i];
            }else{
                $lineP[$i] = '$'.$lineP[$i];
            }
            $result .= ', '.$lineP[$i];
            $i = $i + 1
        }
        $result .= "\n";
    }else{
        $result .="$linePerc[0]".', '."\$$linePerc[1]"."\n";
    }
    return " $result";

}

sub parse_rest {
    my ($content) = @_;
    my $result = '';
    my $countLine = 0;
    $content =~ s/\s*\)\s*$/\;/g;
    $content =~ s/^\s*\(//g;
    @line = split(',',$content);
    my $size = @line;
    my $word = ();
    my $oper =();
    if($size == 1) {
        
        if($line[0] =~ /^\"[A-Za-z0-9]+/) {
            $line[0] =~ s/\"\;$/\\n\"\;/g;
            $result .= $line[0]."\n";
        }
        elsif($line[0] =~ m/[A-Za-z0-9]+/ && $line[0] !~ /\*|\+|\-|\//) {
            if($sysSTDflag == 1){
                    $result .= "\@".$line[0]."\n";
                    $sysSTDflag = 0;
            }
            elsif($line[0] =~ /\s*(.*)\[(.*)\]/){
                my $firstL = $1;
                my $secondL = $2;
                if($firstL =~ /^\s*sys\.argv\s*/){
                    $result .='"'.'$ARGV[';
                }else{
                    $result .= ' "$'.$firstL.'[';
                }
                if($secondL !~ /^\s*[0-9]+\s*$/){
                    $result .= "\$".$secondL;
                }else{
                    $result .= $secondL;
                }
                $result .= ']\n";'."\n";
            }else {
                $line[0] =~ s/[^A-Za-z0-9]+$/\\n\"\;/g;
                $result ='"$' .$line[0]."\n";
            }   
        }elsif($line[0] =~ m/[A-Za-z0-9]+/ && $line[0] =~ /\*|\+|\-|\//) {
            # $line[0] =~ s/\;//g;
            for my $c (split /\s\W\s/, $line[0]) {
                if($c =~ /^\s*[0-9]+(\;)?\s*$/){
                    push @word, $c;
                }
                else{
                    push @word, "\$".$c;
                } 
                # push @word, "\$".$c;
            }
            for my $d (split /[A-Za-z0-9]/,$line[0]){
                if($d =~ /\*|\-|\+|\\/){
                    push @oper,$d; 
                }
            }
            my $i = 0;
            my $size = @oper;
            while($i < $size){
                $result .=$word[$i]." ".$oper[$i]." "; 
                $i++;
            }
            $word[$size] =~ s/\;/\, \"\\n\"\;/g;
            $result .=$word[$size];
            # print "here---\n"; 
        }else{
            $result = '"\n";'."\n";
        }
    }else{     
        my $i  = 0;
        while($i < $size) {  
            if($line[$i] =~ /^\s*end\=(.*)$/){
                $result .= '';
            }elsif($line[$i] =~ /^\s*\"(.*)\"\s*$/){
                if($i > 0){
                    $result .= ', '.$line[$i];
                }else{
                    $result .= $line[$i].' ';
                }
            }else{
                if($line[$i] =~ m/[A-Za-z0-9]+/ && $line[$i] =~ /\*|\+|\-|\//) {
                    if($i > 0){
                        $result .= ', '.'" ",';
                    }
                    $result.= '" ",';
                    for my $c (split /\s\W\s/, $line[$i]) {
                        push @word, "\$".$c;
                    }
                    for my $d (split /[A-Za-z0-9]/,$line[$i]){
                        if($d =~ /\*|\-|\+|\\/){
                            push @oper,$d; 
                        }
                    }
                    my $ii = 0;
                    my $size = @oper;
                    while($ii < $size){
                        $result .=$word[$ii]." ".$oper[$ii]." "; 
                        $ii++;
                    }
                    $word[$size] =~ s/\;/\, \"\\n\"/g;
                    $result .=$word[$size];
                }elsif($line[$i] =~ /\[(.*)\]/){
                    if($1 !~ /^[0-9]+$/){
                        $line[$i] =~ s/\[/\[\$/g;
                    }
                    $result .= '$'.$line[$i];
                }else{
                    $result .= '$'.$line[$i];
                }
                $i = $i + 1;   
            }
            $i++;
        }
        $result .= ';'."\n";
    }
    return " $result";
}

sub parse_scalar {           
    my ($index) = @_;
    my $python = shift @python;
    my $resultS = '';
    my @wordS = ();
    my @operS = ();
    if($python =~ /^\s*\[?\s*(\w+)\]?\s*\=\s*(.*)\s*$/) {
        my $var = $1;
        my $expr = $2;
        if($expr =~ /^\s*sys\.stdin\.readline[s]?\(\)\s*$/){
            $resultS .= " " x ($index)."while (\$line = <STDIN>) {\n";
            $resultS .= " " x ($index+4)."push \@$var,\$line;\n";
            $resultS .= " " x ($index)."\}\n";
            $sysSTDflag = 1;
            return $resultS;
        }elsif($expr =~ /^\s*re\.(.*)$/){
            my $firstRe = $1;
            if($firstRe =~ /^\s*sub\((.*)\)/){
                my $firstS = $1;
                $firstRe =~ /\s*r\'(.*)\'\s?\,\s?\'(.*)\'\s*\,/;
                my $la = $1;
                my $ll = $2;
                $resultS .= "s/";
                $resultS .= "$la";
                $resultS .= "/";
                $resultS .= "$ll";
                $resultS .= "/g";
            }elsif($firstRe =~ /^\s*match\((.*)\)/){
                my $firstM = $1;
                $firstRe =~ /\s*r\'(.*)\'\s?\,\s*/;
                $resultS .= "/";
                $resultS .= "$1";
                $resultS .= "/";
            }
            return " " x ($index)."\$$var"." =~ "."$resultS"."\;\n";
        }elsif($expr =~ /^\s*len\((.*)\)\s*$/){
            if($listFlag == 1){
                $resultS .= "scalar(\@$1)";
                $listFlag = 0;
            }else{
                $resultS .= "scalar(\@$1)";
            }
        }elsif($expr =~ /[^A-Za-z]/ && $expr !~ /\*|\+|\-|\/|\%/) {
            if($expr =~ /sys\.stdin\.readline()/) {
                if($expr =~ /\((.*)\)/){
                    $resultS = '<STDIN>';
                }
            }elsif($expr =~ /^\[\]$/){
                $listFlag = 1;
                return "";
            }elsif($expr =~ /^(\[\]|\{\})$/){
                $hashFlag = 1;
                return "";
            }elsif($expr =~ /^\[(.*)\]$/){
                $listFlag = 1;
                return " " x ($index)."\@$var"." = "."($1)"."\;\n";
            }
            else{
                $resultS = $expr;
            }   
        }elsif($expr =~ /^\s*len\((.*)\)(.*)\s*$/){
            my $firstL = $1;
            my $secondL = $2;
            $resultS = '@'.$firstL.$secondL;
        }elsif($expr =~ /.*/){
            $resultS = '';
            $expr =~ s/\/\//\//g;
            for my $a (split /\s?\W\s?/, $expr) {
                if($a =~ /^[^A-Za-z]$/){
                    push @wordS, $a;
                }
                else{
                    push @wordS, "\$".$a;
                }   
            }
            for my $b (split /\w/,$expr){
                if($b =~ /\*|\-|\+|\/|\%|\/\//){
                    push @operS,$b; 
                }
            }
            my $i = 0;
            my $size = @operS;
            while($i < $size){
                $resultS .=$wordS[$i]." ".$operS[$i]." "; 
                $i++;
            }
            $resultS .=$wordS[$size];
            
        }else{
            print "";
        }
        return " " x ($index)."\$$var"." = "."$resultS"."\;\n";
    }
}

sub parse_if {
    my ($index) = @_; 
    my $python = shift @python;  
    my @if_perl = ();
    if($python !~ /^\s*if(.*)\:$/g) {
        push @if_perl," " x ($index)."if";
        $python =~ /^\s*if(.*)\:(.*)/;
        my $condition = $1;
        my $conditionB = $2;
        push @if_perl,parse_condition($condition);
        if($conditionB =~ /\;/){
            for my $e (split /\;/, $conditionB){
               unshift @python,$e; 
               push @if_perl, parse_statement($index + 4);
            }
        }else{
            unshift @python,$conditionB; 
            push @if_perl, parse_statement($index + 4); 
        }
        push @if_perl," " x ($index)."}\n";
        return @if_perl;
    }
    push @if_perl, " " x($index)."if";
    $python =~ s/(^\s*)if\b//;
    push @if_perl,parse_condition($python);
    my $len2 = 0;
    $python[0] =~ /^(\s*)/;
    $len2 = length($1);
    while(@python) {  
        $python[0] =~ /^(\s*)/;
        my $len3 = length($1);
        if(($len2 != $len3) && ($python[0] !~ /(elif|else)/)){
            last;
        }else{
            if($python[0] =~ /^(\s*)elif(.*)$/) {
                push @if_perl," " x ($index)."} elsif ";
                $python = $python[0];
                $python =~ s/\belif\b//;
                push @if_perl,parse_condition($python);
                shift @python;
            }elsif($python[0] =~ /^(\s*)else(.*)$/){
                 push @if_perl," " x ($index)."} else {\n";
                 shift @python;
            }else{
                push @if_perl, parse_statement($index + 4);
            }
        }
    }
    push @if_perl," " x ($index)."}\n";
    push @if_perl,"";
    return @if_perl;
    
}

sub parse_while {
    my ($index) = @_;
    my $python = shift @python;  
    my @while_perl = ();
    if($python !~ /^\s*while(.*)\:$/g) {
        push @while_perl," " x ($index)."while";
        $python =~ /^\s*while(.*)\:(.*)/;
        my $condition = $1;
        my $conditionB = $2;
        push @while_perl,parse_condition($condition);
        if($conditionB =~ /\;/){
            for my $e (split /\;/, $conditionB){
               unshift @python,$e; 
               push @while_perl, parse_statement($index + 4);
            }
        }else{
            unshift @python,$conditionB; 
            push @while_perl, parse_statement($index + 4); 
        }
        push @while_perl," " x ($index)."}\n";
        return @while_perl;
    }
    push @while_perl," " x ($index)."while";
    $python =~ s/(^\s*)while\b//;
    push @while_perl,parse_condition($python);
    $python[0] =~ /^(\s*)/;
    my $len = length($1);
    while(@python) {
        $python[0] =~ /^(\s*)/;
        my $len1 = length($1);
        if($len != $len1){
            last;
        }else{
            push @while_perl, parse_statement($index + 4);
        }
        
    }
    push @while_perl," " x ($index)."}\n";
    push @while_perl,"";
    return @while_perl;

}
sub parse_condition {
    (my $python) = @_;
    my $second = '';
    if($python =~ /(.*) (and|not|or) (.*)/){
        my $firstPart = $1; 
        my $secondPart = $2;
        my $thirdPart = $3;
        if($secondPart =~ /and/){
            $python =~ s/ and / \$\$ /g;
        }elsif($secondPart =~ /not/){
            $python =~ s/ not / \!\= /g;
        }elsif($secondPart =~ /or/){
            $python =~ s/ or / \|\| /g;
        }
        $firstPart = logicalStatement($firstPart);
        $thirdPart = logicalStatement($thirdPart);
        return ' ('.$firstPart.' '.$secondPart.' '.$thirdPart.') {'."\n";
    }
    if($python =~ /(^\s*)*(.*)(\:)?/){
        my $indent = $1;
        my $condition = $2;
        $condition =~ s/\://g;
        if($condition =~ /\s*(.*)\s*\=\=\s*(.*)/){        
            $condition = "("."\$$1"."==";
            $second = $2;
            if($second =~ /[^A-Za-z]/){
                $condition .=" $second".")";
            }else{
                $condition .=" \$$second".")";
            }
        }
        elsif($condition =~ /\s*(.*)\s*\<\=\s*(.*)/){
            $condition = "("."\$$1"."<=";
            $second = $2;
            if($second =~ /[^A-Za-z]/){
                $condition .=" $second".")";
            }else{
                $condition .=" \$$second".")";
            }
            
        }
        elsif($condition =~ /\s*(.*)\s*\>\=\s*(.*)/){
            $condition = "("."\$$1".">=";
            $second = $2;
            if($second =~ /[^A-Za-z]/){
                $condition .=" $second".")";
            }else{
                $condition .=" \$$second".")";
            }
        }
        elsif($condition =~ /\s*(.*)\s*\<\s*(.*)/){
            $condition = "("."\$$1"."<";
            $second = $2;
            if($second =~ /[^A-Za-z]/){
                $condition .=" $second".")";
            }else{
                $condition .=" \$$second".")";
            }
        }
        elsif($condition =~ /\s*(.*)\s*\>\s*(.*)/){
            $condition = "("."\$$1".">";
            $second = $2;
            if($second =~ /[^A-Za-z]/){
                $condition .=" $second".")";
            }else{
                $condition .=" \$$second".")";
            }
        }
        elsif($condition =~ /\s*(.*)\s*\!\=\s*(.*)/){
            $condition = "("."\$$1"."!=";
            $second = $2;
            if($second =~ /[^A-Za-z]/){
                $condition .=" $second".")";
            }else{
                $condition .=" \$$second".")";
            }
        }
        return "$indent"."$condition"." {\n" if $indent;
        return "$condition"."{\n"
    }
}

sub logicalStatement {
    (my $python) = @_;
    $python =~ s/\://g;
    if($python =~ /\s*(.*)\s*\=\=\s*(.*)/){      
            $python = "\$$1"."==";
            $second = $2;
            if($second =~ /^\s*[0-9]+\s*$/){
                $python .=" $second";
            }else{
                $python .=" \$$second";
            }
        }
        elsif($python =~ /\s*(.*)\s*\<\=\s*(.*)/){
            $python = "\$$1"."<=";
            $second = $2;
            if($second =~ /^\s*[0-9]+\s*$/){
                $python .=" $second";
            }else{
                $python .=" \$$second";
            }
            
        }
        elsif($python =~ /\s*(.*)\s*\>\=\s*(.*)/){
            $python = "\$$1".">=";
            $second = $2;
            if($second =~ /^\s*[0-9]+\s*$/){
                $python .=" $second";
            }else{
                $python .=" \$$second";
            }
        }
        elsif($python =~ /\s*(.*)\s*\<\s*(.*)/){
            $python = "\$$1"."<";
            $second = $2;
            if($second =~ /^\s*[0-9]+\s*$/){
                $python .=" $second";
            }else{
                $python .=" \$$second";
            }
        }
        elsif($python =~ /\s*(.*)\s*\>\s*(.*)/){
            $python = "\$$1".">";
            $second = $2;
            if($second =~ /^\s*[0-9]+\s*$/){
                $python .=" $second";
            }else{
                $python .=" \$$second";
            }
        }
        elsif($python =~ /\s*(.*)\s*\!\=\s*(.*)/){
            $python = "\$$1"."!=";
            $second = $2;
            if($second =~ /^\s*[0-9]+\s*$/){
                $python .=" $second";
            }else{
                $python .=" \$$second";
            }
        }
    return $python;
}

sub parse_head {
    my $python = shift @python;
    return "#!/usr/bin/perl -w\n";
}

# array to store each line of python file
our @python = <>;
#array to store the output line by line
our @perl = ();
$sysSTDflag = 0;
$sysLenflag = 0;
$hashFlag = 0;
$listFlag = 0;
#change the first line
push @perl,parse_head();
while(@python) {
    push @perl, parse_statement(0);
}
print @perl;