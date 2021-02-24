#!/usr/bin/env lua
-- -*- coding: utf-8 -*-


-- 
-- O Enigma das três portas, aka Paradoxo de Monty Hall
-- 
-- Essa é uma implementação do problema discutido ontem em sala. Eu tenho
-- certeza (quase) absoluta de que todos entenderão o paradoxo LENDO o
-- código e não executando-o, pois um detalhe sutil vem à luz quando o
-- problema é colocado em termos mais formais.
--
-- Qualquer coisa, mail-me: aittner ARROBA netuno.com.br
--



-- Gera um entre 1 e três para escolha da porta, com o melhor gerador de
-- números pseudoaleatórios disponível no seu sistema operacional. Se você
-- não entender as próximas linhas, não se preocupe e continue lendo.

local fp = io.open("/dev/urandom", "r")
local getdoor
if fp then
  function getdoor()
    return math.mod(fp:read(1):byte(), 3) + 1
  end
else
  print("Usando Windows, hein?! Os números não serão tão aleatórios...")
  math.randomseed(os.time())
  function getdoor()
    return math.random(1, 3)
  end
end


-- Total de testes efetuados. Faz 10.000 testes, a menos que outro valor
-- seja especificado pela linha de comando.

local total = 10000
if arg[1] then 
  total = tonumber(arg[1])
end


local pm = 0    -- Prêmios ganhos MANTENDO a porta.
local pt = 0    -- Prêmios ganhos TROCANDO de porta.


for i = 1, total do

  -- O prêmio está em uma das portas.
  local ep = getdoor()

  -- O convidado escolhe sua porta.
  local ec = getdoor()

  -- O apresentador escolhe uma porta restante SEM PRÊMIO. Ou seja, ele
  -- sempre escolhe uma porta diferente da que possui o prêmio e diferente
  -- da escolhida pelo convidado. Abaixo, você notará que sequer precisamos
  -- guardar em variáveis qual porta ele escolheu!

  local ea
  if ep ~= 1 and ec ~= 1 then
    ea = 1
  elseif ep ~= 2 and ec ~= 2 then
    ea = 2
  else
    ea = 3
  end

  -- Opção 1: O convidado mantém a escolha. Se for igual a 'ep', ganhou.
  if ec == ep then
    pm = pm + 1
  end

  -- Opção 2: O convidado troca de porta. Como o apresentador escolheu uma
  -- porta diferente da escolhida pelo convidado e que NÃO tem o prêmio, o
  -- convidado ganhará se o prêmio NÃO estiver na porta anteriormente
  -- escolhida por ele. É aqui que está a razão dos 2/3!

  if ec ~= ep then
    pt = pt + 1
  end

  -- Agora você já deve ter notado a sutileza do problema: para ganhar sem
  -- trocar de porta, o convidado precisa escolher a porta certa (um terço
  -- de chance). Mas, para ganhar trocando de porta, basta escolher uma
  -- porta ERRADA no início! (dois terços de chance).

end

-- Eu disse que você não precisaria executar o código para entender. Mas, se
-- não estiver convencido ainda, vá em frente ;)

if fp then
  fp:close()
end

print("Total: " .. total )
print("Acertos MANTENDO a porta : " .. pm .. " (" .. pm/total*100 .. "%)")
print("Acertos TROCANDO de porta: " .. pt .. " (" .. pt/total*100 .. "%)")

